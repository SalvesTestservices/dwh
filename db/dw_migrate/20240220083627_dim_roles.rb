class DimRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_roles do |t|
      t.string  :uid
      t.string  :role
      t.string  :category

      t.timestamps
    end
    add_index :dim_roles, [:uid], unique: true
  end
end