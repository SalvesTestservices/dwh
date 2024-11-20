class DpRuns < ActiveRecord::Migration[7.0]
  def change
    create_table :dp_runs do |t|
      t.integer   :account_id
      t.string    :status, default: "new"
      t.datetime  :started_at
      t.datetime  :finished_at
      t.integer   :dp_pipeline_id

      t.timestamps
    end
    add_index :dp_runs, :account_id
    add_index :dp_runs, :status
    add_index :dp_runs, :dp_pipeline_id
  end
end