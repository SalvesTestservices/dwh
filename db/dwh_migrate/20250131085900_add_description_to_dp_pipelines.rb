class AddDescriptionToDpPipelines < ActiveRecord::Migration[7.0]
  def change
    add_column :dp_pipelines, :description, :string
  end
end 
