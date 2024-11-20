class DimLedger < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_ledgers do |t|
      t.integer :account_id
      t.string  :original_reknr
      t.string  :reknr
      t.string  :description
      t.string  :origin
      t.string  :administration

      t.timestamps
    end
    add_index :dim_ledgers, :account_id
    add_index :dim_ledgers, :reknr
    add_index :dim_ledgers, :origin
    add_index :dim_ledgers, :administration
  end
end
