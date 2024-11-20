class DpQualityChecks < ActiveRecord::Migration[7.0]
  def change
    create_table :dp_quality_checks do |t|
      t.integer :dp_run_id
      t.integer :dp_task_id
      t.string  :check_type
      t.string  :description
      t.integer :expected
      t.integer :actual
      t.string  :result

      t.timestamps
    end
    add_index :dp_quality_checks, :dp_run_id
    add_index :dp_quality_checks, :dp_task_id
    add_index :dp_quality_checks, :check_type
    add_index :dp_quality_checks, :result
  end
end