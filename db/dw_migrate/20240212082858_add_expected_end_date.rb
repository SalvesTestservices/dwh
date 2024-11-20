class AddExpectedEndDate < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_projectusers, :expected_end_date, :date
    add_column :fact_contracts, :expected_end_date, :date
    add_index :dim_projectusers, :expected_end_date
    add_index :fact_contracts, :expected_end_date
  end
end
