class AddBrokerToDimProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_projects, :broker, :string
    add_index :dim_projects, :broker
  end
end


