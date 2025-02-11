class DimAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_accounts do |t|
      t.integer :original_id
      t.string  :name
      t.string  :is_holding
      t.string  :administration_globe
      t.string  :administration_synergy

      t.timestamps
    end
    add_index :dim_accounts, [:original_id], unique: true    
    add_index :dim_accounts, :is_holding
    add_index :dim_accounts, :administration_globe
    add_index :dim_accounts, :administration_synergy
  end
end