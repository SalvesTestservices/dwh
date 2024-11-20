class AddDatesToDimProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_projects, :start_date, :integer
    add_column :dim_projects, :end_date, :integer
    add_index :dim_projects, :start_date
    add_index :dim_projects, :end_date
  end
end
