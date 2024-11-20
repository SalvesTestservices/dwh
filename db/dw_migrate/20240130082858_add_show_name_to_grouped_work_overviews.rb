class AddShowNameToGroupedWorkOverviews < ActiveRecord::Migration[7.1]
  def change
    add_column :bb_grouped_work_overviews, :show_name, :boolean
    add_index :bb_grouped_work_overviews, :show_name
  end
end
