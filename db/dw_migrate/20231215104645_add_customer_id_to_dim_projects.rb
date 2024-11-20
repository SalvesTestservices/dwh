class AddCustomerIdToDimProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_projects, :customer_id, :integer
    add_index :dim_projects, :customer_id
  end
end
