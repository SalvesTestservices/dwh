class AddPipelineKeyToDpPipelines < ActiveRecord::Migration[7.1]
  def change
    add_column :dp_pipelines, :pipeline_key, :string
    add_index :dp_pipelines, :pipeline_key, unique: true
  end
end
