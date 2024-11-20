class DpPipelines < ActiveRecord::Migration[7.0]
  def change
    create_table :dp_pipelines do |t|
      t.string    :name
      t.string    :description
      t.string    :status, default: "inactive"
      t.datetime  :last_executed_at
      t.integer   :frequency, default: 24
      t.string    :load_method, default: "incremental"
      t.integer   :dp_tasks_count, default: 0
      t.integer   :dp_runs_count, default: 0
      t.jsonb     :account_ids, default: []

      t.timestamps
    end
    add_index :dp_pipelines, :name, unique: true
    add_index :dp_pipelines, :status
    add_index :dp_pipelines, :last_executed_at
    add_index :dp_pipelines, :frequency
    add_index :dp_pipelines, :load_method
    add_index :dp_pipelines, :dp_tasks_count
    add_index :dp_pipelines, :dp_runs_count
    add_index :dp_pipelines, :account_ids, using: :gin
  end
end