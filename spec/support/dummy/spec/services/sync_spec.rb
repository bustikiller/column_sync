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
end
