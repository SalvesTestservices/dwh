class DimHolidays < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_holidays do |t|
      t.string  :uid
      t.integer :account_id
      t.integer :company_id
      t.integer :holiday_date
      t.string  :name
      t.string  :country

      t.timestamps
    end
    add_index :dim_holidays, [:uid], unique: true
    add_index :dim_holidays, :account_id
    add_index :dim_holidays, :company_id
    add_index :dim_holidays, :holiday_date
    add_index :dim_holidays, :country
  end
end
