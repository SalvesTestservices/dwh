class AddExpectedEndDateToDimProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_projects, :expected_end_date, :integer
    add_index :dim_projects, :expected_end_date
  end
end
