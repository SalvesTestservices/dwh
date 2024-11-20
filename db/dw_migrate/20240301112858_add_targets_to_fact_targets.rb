class AddTargetsToFactTargets < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_targets, :employee_attrition, :decimal
    add_column :fact_targets, :employee_absence, :decimal
    add_index :fact_targets, :employee_attrition
    add_index :fact_targets, :employee_absence
  end
end