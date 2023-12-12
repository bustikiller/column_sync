class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :company, null: false, foreign_key: true
      t.datetime :expires_at
      t.string :country_code

      t.timestamps
    end
  end
end
