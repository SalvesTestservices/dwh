class AddPositionToDpPipelines < ActiveRecord::Migration[7.1]
  def change
    add_column :dp_pipelines, :position, :integer
    add_index :dp_pipelines, :position
  end
end
