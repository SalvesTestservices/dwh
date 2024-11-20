class RemoveUniqueIndexOnDpPipelines < ActiveRecord::Migration[6.0]
  def change
    remove_index :dp_pipelines, name: "index_dp_pipelines_on_pipeline_key"
    add_index :dp_pipelines, :pipeline_key
  end
end