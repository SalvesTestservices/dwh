class FactBalances < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_balances do |t|
      t.integer :account_id
      t.integer :user_id
      t.integer :year
      t.decimal :previous_balance, precision: 10, scale: 2
      t.decimal :start_rights, precision: 10, scale: 2
      t.decimal :start_balance, precision: 10, scale: 2

      t.timestamps
    end
    add_index :fact_balances, [:account_id, :user_id, :year], unique: true
    add_index :fact_balances, :account_id
    add_index :fact_balances, :user_id
    add_index :fact_balances, :year
  end
end