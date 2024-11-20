class AddScopedUserIdToDpPipelines < ActiveRecord::Migration[7.1]
  def change
    add_column :dp_pipelines, :scoped_user_id, :integer
    add_index :dp_pipelines, :scoped_user_id
  end
end
