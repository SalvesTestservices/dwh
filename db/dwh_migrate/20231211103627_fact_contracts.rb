class FactContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_contracts do |t|
      t.integer :account_id
      t.string :original_id
      t.integer :customer_id
      t.integer :user_id
      t.integer :company_id
      t.integer :projectuser_id
      t.integer :project_id
      t.integer :contract_date
      t.string  :contract_type
      t.string  :description
      t.integer :start_date
      t.integer :end_date
      t.integer :expected_end_date

      t.timestamps
    end
    add_index :fact_contracts, [:account_id, :original_id], unique: true
    add_index :fact_contracts, :account_id
    add_index :fact_contracts, :original_id
    add_index :fact_contracts, :customer_id
    add_index :fact_contracts, :user_id
    add_index :fact_contracts, :company_id
    add_index :fact_contracts, :projectuser_id
    add_index :fact_contracts, :project_id
    add_index :fact_contracts, :contract_date
    add_index :fact_contracts, :contract_type
    add_index :fact_contracts, :start_date
    add_index :fact_contracts, :end_date
    add_index :fact_contracts, :expected_end_date
  end
end
