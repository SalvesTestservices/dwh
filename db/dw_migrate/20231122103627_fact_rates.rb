class FactRates < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_rates do |t|
      t.integer :account_id
      t.integer :company_id
      t.integer :user_id
      t.integer :year
      t.integer :month
      t.string  :month_long
      t.decimal :hours, precision: 10, scale: 2
      t.decimal :avg_rate, precision: 10, scale: 2
      t.decimal :bcr, precision: 10, scale: 2
      t.decimal :ucr, precision: 10, scale: 2
      t.decimal :company_bcr, precision: 10, scale: 2
      t.decimal :company_ucr, precision: 10, scale: 2
      t.string  :contract
      t.decimal :contract_hours, precision: 10, scale: 2
      t.decimal :salary, precision: 10, scale: 2

      t.timestamps
    end
    add_index :fact_rates, :account_id
    add_index :fact_rates, :company_id
    add_index :fact_rates, :user_id
    add_index :fact_rates, :year
    add_index :fact_rates, :month
    add_index :fact_rates, :contract
  end
end