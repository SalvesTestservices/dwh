class UpdateDimUsersIndex < ActiveRecord::Migration[8.0]
  def change
    # Remove existing index
    remove_index :dim_users, name: "index_dim_users_on_account_id_and_original_id"
    
    # Add new composite index
    add_index :dim_users, [:account_id, :original_id, :company_id], unique: true, name: "index_dim_users_on_account_id_and_original_id_and_company_id"
  end
end 