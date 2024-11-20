class AddYearAndMonthToFactLedgerMutations < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_ledger_mutations, :year, :integer
    add_column :fact_ledger_mutations, :month, :integer
    add_index :fact_ledger_mutations, :year
    add_index :fact_ledger_mutations, :month
  end
end
