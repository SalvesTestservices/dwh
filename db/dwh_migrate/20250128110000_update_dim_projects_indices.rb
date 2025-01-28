class UpdateDimProjectsIndices < ActiveRecord::Migration[7.0]
  def change
    remove_index :dim_projects, name: 'index_dim_projects_on_acc_id_orig_id_start_end'
    
    add_index :dim_projects, [:account_id, :original_id], unique: true, name: 'index_dim_projects_on_account_id_and_original_id'
  end
end 