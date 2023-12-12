class SyncColumns < ActiveRecord::Migration[7.1]
  def up
    sync_columns(Subscription => :country_code, Company => :country)
  end

  def down
    unsync_columns(Subscription => :country_code, Company => :country)
  end
end
