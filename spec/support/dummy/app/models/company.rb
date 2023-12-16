class Company < ApplicationRecord
  include ColumnSync::Model
  
  has_one :subscription

  sync_column :country, to: :subscription, column: :country_code
end
