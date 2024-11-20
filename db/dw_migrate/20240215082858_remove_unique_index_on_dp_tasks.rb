class RemoveUniqueIndexOnDpTasks < ActiveRecord::Migration[6.0]
  def change
    remove_index :dp_tasks, name: "index_dp_tasks_on_task_key"
    add_index :dp_tasks, :task_key
  end
end