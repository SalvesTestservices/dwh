class FactRates < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_rates do |t|
      t.integer :account_id
      t.integer :company_id
      t.integer :user_id
      t.integer :rate_date
      t.decimal :hours, precision: 10, scale: 2
      t.decimal :avg_rate, precision: 10, scale: 2
      t.decimal :bcr, precision: 10, scale: 2
      t.decimal :ucr, precision: 10, scale: 2
      t.decimal :company_bcr, precision: 10, scale: 2
      t.decimal :company_ucr, precision: 10, scale: 2
      t.string  :contract
      t.decimal :contract_hours, precision: 10, scale: 2
      t.decimal :salary, precision: 10, scale: 2
      t.string  :role
      t.string  :show_user, default: "Y"

      t.timestamps
    end
    add_index :fact_rates, [:account_id, :user_id, :rate_date], unique: true
    add_index :fact_rates, :account_id
    add_index :fact_rates, :company_id
    add_index :fact_rates, :user_id
    add_index :fact_rates, :rate_date
    add_index :fact_rates, :contract
    add_index :fact_rates, :role
    add_index :fact_rates, :show_user
  end
end