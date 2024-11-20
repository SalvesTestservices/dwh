class AddTargetDateToFactTargets < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_targets, :target_date, :integer
    rename_column :fact_targets, :role, :role_group
    add_index :fact_targets, :target_date
    add_column :dim_users, :role_group, :string
    add_index :dim_users, :role_group
  end
end
