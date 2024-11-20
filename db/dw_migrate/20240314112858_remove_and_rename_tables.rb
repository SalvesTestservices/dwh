class RemoveAndRenameTables < ActiveRecord::Migration[7.1]
  def change
    drop_table :fact_contracts

    rename_table :dim_projectusers, :fact_projectusers
  end
end