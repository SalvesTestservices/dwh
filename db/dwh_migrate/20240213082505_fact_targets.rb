class FactTargets < ActiveRecord::Migration[7.1]
  def change
    create_table :fact_targets do |t|
      t.string  :uid
      t.integer :account_id
      t.string :original_id
      t.integer :company_id
      t.integer :year
      t.integer :month
      t.string :role_group
      t.decimal :fte
      t.integer :billable_hours
      t.decimal :cost_price
      t.decimal :bruto_margin
      t.integer :target_date
      t.integer :workable_hours
      t.decimal :productivity, precision: 5, scale: 2
      t.decimal :hour_rate, precision: 5, scale: 2
      t.decimal :turnover, precision: 10, scale: 2
      t.integer :quarter
      t.decimal :employee_attrition
      t.decimal :employee_absence

      t.timestamps
    end
    add_index :fact_targets, [:uid], unique: true
    add_index :fact_targets, :account_id
    add_index :fact_targets, :original_id
    add_index :fact_targets, :company_id
    add_index :fact_targets, :year
    add_index :fact_targets, :month
    add_index :fact_targets, :role_group
    add_index :fact_targets, :target_date
    add_index :fact_targets, :quarter
    add_index :fact_targets, :employee_attrition
    add_index :fact_targets, :employee_absence
  end
end