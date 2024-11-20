class DpTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :dp_tasks do |t|
      t.string    :name
      t.string    :task_key
      t.string    :description
      t.string    :status, default: "active"
      t.integer   :sequence
      t.jsonb     :depends_on, default: []
      t.integer   :dp_pipeline_id

      t.timestamps
    end
    add_index :dp_tasks, :name
    add_index :dp_tasks, :task_key, unique: true
    add_index :dp_tasks, :sequence
    add_index :dp_tasks, :dp_pipeline_id
    add_index :dp_tasks, :status
  end
end