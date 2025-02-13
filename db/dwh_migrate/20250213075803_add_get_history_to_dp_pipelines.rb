class AddGetHistoryToDpPipelines < ActiveRecord::Migration[8.0]
  def change
    add_column :dp_pipelines, :get_history, :string, default: "last_day"
    add_index :dp_pipelines, :get_history
  end
end
