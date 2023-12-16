class Subscription < ApplicationRecord
  include ColumnSync::Model

  belongs_to :company

  sync_column :country_code, to: :company, column: :country
end
