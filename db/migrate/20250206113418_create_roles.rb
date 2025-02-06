class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name
      t.string :permissions, array: true, default: []
      
      t.timestamps
    end

    add_index :roles, :permissions, using: 'gin'
  end
end
