class AddIndexesForDw < ActiveRecord::Migration[7.1]
  def change
    add_index :dim_unbillables, [:account_id, :original_id], unique: true
    add_index :dim_companies, [:account_id, :original_id], unique: true
    add_index :dim_projects, [:account_id, :original_id], unique: true
    add_index :dim_projectusers, [:account_id, :original_id], unique: true
    add_index :dim_ledgers, [:account_id, :origin, :administration, :reknr], unique: true
    add_index :dim_customers, [:account_id, :original_id], unique: true
    add_index :dim_users, [:account_id, :original_id], unique: true
    add_index :fact_contracts, [:account_id, :original_id], unique: true
    add_index :fact_activities, [:account_id, :original_id], unique: true
    add_index :fact_rates, [:account_id, :user_id, :rate_date], unique: true
    add_index :fact_ledger_mutations, [:account_id, :origin, :administration, :reknr], unique: true

    remove_index :dim_accounts, [:original_id]
    add_index :dim_accounts, [:original_id], unique: true
  end
end