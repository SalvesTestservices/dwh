class RemoveRoleGroupFromDimUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :dim_users, :role_group, :string
  end
end
