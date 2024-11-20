class RecreateExpectedEndDate < ActiveRecord::Migration[7.1]
  def change
    remove_index :dim_projectusers, :expected_end_date
    remove_column :dim_projectusers, :expected_end_date, :date
    add_column :dim_projectusers, :expected_end_date, :integer
    add_index :dim_projectusers, :expected_end_date
    remove_index :fact_contracts, :expected_end_date
    remove_column :fact_contracts, :expected_end_date, :date
    add_column :fact_contracts, :expected_end_date, :integer
    add_index :fact_contracts, :expected_end_date
  end
end
