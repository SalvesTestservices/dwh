class DpResults < ActiveRecord::Migration[7.0]
  def change
    create_table :dp_results do |t|
      t.integer   :dp_task_id
      t.integer   :dp_run_id
      t.string    :job_id
      t.string    :status
      t.string    :error
      t.jsonb     :depends_on, default: []
      t.datetime  :started_at
      t.datetime  :finished_at

      t.timestamps
    end
    add_index :dp_results, :dp_task_id
    add_index :dp_results, :dp_run_id
    add_index :dp_results, :status
    add_index :dp_results, :job_id
  end
end