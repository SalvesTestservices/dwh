class AddQuarterToFactTargets < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_targets, :quarter, :integer
    add_index :fact_targets, :quarter
  end
end
