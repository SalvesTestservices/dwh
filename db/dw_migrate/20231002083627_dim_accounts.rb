class DimAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_accounts do |t|
      t.integer :original_id
      t.string  :name
      t.string  :is_holding

      t.timestamps
    end
    add_index :dim_accounts, :original_id
    add_index :dim_accounts, :is_holding
  end
end