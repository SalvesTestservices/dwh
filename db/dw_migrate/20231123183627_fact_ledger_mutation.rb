class FactLedgerMutation < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_ledger_mutations do |t|
      t.integer :account_id
      t.string  :original_reknr
      t.string  :reknr
      t.string  :description
      t.string  :origin
      t.string  :administration
      t.decimal :amount, precision: 10, scale: 2
      t.integer :year
      t.integer  :month

      t.timestamps
    end
    add_index :fact_ledger_mutations, :account_id
    add_index :fact_ledger_mutations, :reknr
    add_index :fact_ledger_mutations, :origin
    add_index :fact_ledger_mutations, :administration
    add_index :fact_ledger_mutations, :year
    add_index :fact_ledger_mutations, :month
  end
end
