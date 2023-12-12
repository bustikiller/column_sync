require "rails_helper"

RSpec.describe "column synchronization" do
  before do
    Company.create!(name: "Company 1", country: "US")
    Company.create!(name: "Company 2", country: "MX")
    Company.create!(name: "Company 3", country: "CA")

    Subscription.create!(company: Company.first, country_code: "US")
    Subscription.create!(company: Company.second, country_code: "MX")
    Subscription.create!(company: Company.third, country_code: "CA")
  end

  it "syncs from company to subscription" do
    expect(Subscription.first.country_code).to eq "US"
    expect(Subscription.second.country_code).to eq "MX"
    expect(Subscription.third.country_code).to eq "CA"

    Company.first.update!(country: "ES")
    Company.second.update!(country: "AF")
    Company.third.update!(country: "AD")

    expect(Subscription.first.country_code).to eq "ES"
    expect(Subscription.second.country_code).to eq "AF"
    expect(Subscription.third.country_code).to eq "AD"
  end

  it "syncs from subscription to company" do
    expect(Company.first.country).to eq "US"
    expect(Company.second.country).to eq "MX"
    expect(Company.third.country).to eq "CA"

    Subscription.first.update!(country_code: "ES")
    Subscription.second.update!(country_code: "AF")
    Subscription.third.update!(country_code: "AD")

    expect(Company.first.country).to eq "ES"
    expect(Company.second.country).to eq "AF"
    expect(Company.third.country).to eq "AD"
  end
end
