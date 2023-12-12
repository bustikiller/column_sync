require "rails_helper"

RSpec.describe ColumnSync::Service do
  let(:service) { described_class.new(Subscription => :country_code, Company => :country) }
  describe "#initialize" do
    it "raises an error if columns is not a hash" do
      expect { described_class.new("foo") }.to raise_error(ArgumentError)
    end

    it "raises an error if no column is provided" do
      expect { described_class.new({}) }.to raise_error(ArgumentError)
    end

    it "raises an error if only one column is provided" do
      expect { described_class.new(Company => :country) }.to raise_error(ArgumentError)
    end

    it "raises an error if more than two columns are provided" do
      expect do
        described_class.new(
          Company => :country,
          Subscription => :country_code,
          User => :name
        )
      end.to raise_error(ArgumentError)
    end

    it "raises an error if no valid column relation is found" do
      expect do
        described_class.new(Company => :country_code, User => :name)
      end.to raise_error(ArgumentError)
    end

    it "raises an error if the referenced column does not exist" do
      expect do
        described_class.new(Company => :foo, Subscription => :country_code)
      end.to raise_error(ArgumentError)
    end

    it "raises an error if the referencer column does not exist" do
      expect do
        described_class.new(Company => :country, Subscription => :foo)
      end.to raise_error(ArgumentError)
    end

    context "when a valid column relation is provided" do
      it { expect(service.referenced_table_name).to eq "companies" }
      it { expect(service.referenced_column_name).to eq "country" }
      it { expect(service.referenced_primary_key).to eq "id" }
      it { expect(service.referencer_table_name).to eq "subscriptions" }
      it { expect(service.referencer_column_name).to eq "country_code" }
      it { expect(service.referencer_fk_column_name).to eq "company_id" }
    end
  end

  describe "#functions" do
    it "returns a function per table" do
      expect(service.functions.keys).to contain_exactly(
        "column_sync_subscriptions_country_code_on_companies_update",
        "column_sync_companies_country_on_subscriptions_update"
      )
    end

    it "returns a function for updates on the referenced table" do
      expect(service.functions["column_sync_subscriptions_country_code_on_companies_update"].squish).to eq <<~SQL.squish
        CREATE OR REPLACE FUNCTION column_sync_subscriptions_country_code_on_companies_update()
        RETURNS TRIGGER AS $$
        BEGIN
        IF NEW.country IS DISTINCT FROM OLD.country THEN
          UPDATE subscriptions
          SET country_code = NEW.country
          WHERE company_id = NEW.id;
        END IF;
        RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
    end

    it "returns a function for updates on the referencer table" do
      expect(service.functions["column_sync_companies_country_on_subscriptions_update"].squish).to eq <<~SQL.squish
        CREATE OR REPLACE FUNCTION column_sync_companies_country_on_subscriptions_update()
        RETURNS TRIGGER AS $$
        BEGIN
        IF NEW.country_code IS DISTINCT FROM OLD.country_code THEN
          UPDATE companies
          SET country = NEW.country_code
          WHERE id = NEW.company_id;
        END IF;
        RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
    end
  end

  describe "#triggers" do
    it "returns a trigger per table" do
      expect(service.triggers.keys).to contain_exactly(
        "column_sync_subscriptions_country_code_on_companies_update",
        "column_sync_companies_country_on_subscriptions_update"
      )
    end

    it "returns a trigger for updates on the referenced table" do
      expect(service.triggers["column_sync_subscriptions_country_code_on_companies_update"][:definition].squish).to eq <<~SQL.squish
        CREATE TRIGGER column_sync_subscriptions_country_code_on_companies_update
        AFTER UPDATE ON companies
        FOR EACH ROW
        EXECUTE PROCEDURE column_sync_subscriptions_country_code_on_companies_update();
      SQL
    end

    it "returns a trigger for updates on the referencer table" do
      expect(service.triggers["column_sync_companies_country_on_subscriptions_update"][:definition].squish).to eq <<~SQL.squish
        CREATE TRIGGER column_sync_companies_country_on_subscriptions_update
        AFTER UPDATE ON subscriptions
        FOR EACH ROW
        EXECUTE PROCEDURE column_sync_companies_country_on_subscriptions_update();
      SQL
    end

    it {
      expect(service.triggers["column_sync_subscriptions_country_code_on_companies_update"][:table_name]).to eq "companies"
    }
    it {
      expect(service.triggers["column_sync_companies_country_on_subscriptions_update"][:table_name]).to eq "subscriptions"
    }
  end
end
