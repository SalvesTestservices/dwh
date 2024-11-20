class AddNewIndexToDimProjects < ActiveRecord::Migration[7.1]
  def change
    remove_index :dim_projects, name: 'index_dim_projects_on_account_id_and_original_id', column: [:account_id, :original_id]
    add_index :dim_projects, [:account_id, :original_id, :start_date, :end_date], unique: true
  end
end
