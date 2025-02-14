class AddKeyToRoles < ActiveRecord::Migration[8.0]
  def change
    add_column :roles, :key, :string
    add_index :roles, :key, unique: true
  end
end 