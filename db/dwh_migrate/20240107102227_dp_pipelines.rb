class DpPipelines < ActiveRecord::Migration[7.0]
  def change
    create_table :dp_pipelines do |t|
      t.string    :name
      t.string    :status, default: "inactive"
      t.datetime  :last_executed_at
      t.integer   :frequency, default: 24
      t.string    :load_method, default: "incremental"
      t.integer   :dp_tasks_count, default: 0
      t.integer   :dp_runs_count, default: 0
      t.string    :account
      t.string    :pipeline_key
      t.integer   :month
      t.integer   :year
      t.integer   :position
      t.integer   :scoped_user_id

      t.timestamps
    end
    add_index :dp_pipelines, :name
    add_index :dp_pipelines, :status
    add_index :dp_pipelines, :last_executed_at
    add_index :dp_pipelines, :frequency
    add_index :dp_pipelines, :load_method
    add_index :dp_pipelines, :dp_tasks_count
    add_index :dp_pipelines, :dp_runs_count
    add_index :dp_pipelines, :account
    add_index :dp_pipelines, :pipeline_key, unique: true
    add_index :dp_pipelines, :month
    add_index :dp_pipelines, :year
    add_index :dp_pipelines, :position
    add_index :dp_pipelines, :scoped_user_id
  end
end