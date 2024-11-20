class DpLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :dp_logs do |t|
      t.integer   :dp_run_id
      t.string    :message
      t.string    :status
      t.datetime  :started_at
      t.datetime  :finished_at

      t.timestamps
    end
    add_index :dp_logs, :dp_run_id
    add_index :dp_logs, :status
  end
end