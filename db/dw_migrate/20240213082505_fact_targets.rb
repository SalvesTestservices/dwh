class FactTargets < ActiveRecord::Migration[7.1]
  def change
    create_table :fact_targets do |t|
      t.bigint  :uid
      t.integer :account_id
      t.integer :original_id
      t.integer :company_id
      t.integer :year
      t.integer :month
      t.string :role
      t.decimal :fte
      t.integer :billable_hours
      t.decimal :cost_price
      t.decimal :bruto_margin

      t.timestamps
    end
    add_index :fact_targets, [:uid], unique: true
    add_index :fact_targets, :account_id
    add_index :fact_targets, :original_id
    add_index :fact_targets, :company_id
    add_index :fact_targets, :year
    add_index :fact_targets, :month
    add_index :fact_targets, :role
  end
end