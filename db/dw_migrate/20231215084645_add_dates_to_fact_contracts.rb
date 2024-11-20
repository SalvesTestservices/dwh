class AddDatesToFactContracts < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_contracts, :start_date, :integer
    add_column :fact_contracts, :end_date, :integer
    add_index :fact_contracts, :start_date
    add_index :fact_contracts, :end_date
  end
end
