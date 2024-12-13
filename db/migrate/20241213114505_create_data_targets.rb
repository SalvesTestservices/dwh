class CreateDataTargets < ActiveRecord::Migration[7.1]
  def change
    create_table :data_targets do |t|
      t.integer :account_id
      t.integer :company_id
      t.integer :year
      t.integer :month
      t.string :role
      t.decimal :fte
      t.integer :billable_hours
      t.decimal :cost_price
      t.decimal :bruto_margin
      t.integer :quarter
      t.decimal :employee_attrition
      t.decimal :employee_absence

      t.timestamps
    end
    add_index :data_targets, :account_id
    add_index :data_targets, :company_id
    add_index :data_targets, :year
    add_index :data_targets, :month
    add_index :data_targets, :role
    add_index :data_targets, :quarter
    add_index :data_targets, :employee_attrition
    add_index :data_targets, :employee_absence
  end
end