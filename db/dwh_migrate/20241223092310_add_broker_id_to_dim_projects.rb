class AddBrokerIdToDimProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_projects, :broker_id, :integer
    add_index :dim_projects, :broker_id
  end
end


