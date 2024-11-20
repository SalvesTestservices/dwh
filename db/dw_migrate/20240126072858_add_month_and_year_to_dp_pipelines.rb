class AddMonthAndYearToDpPipelines < ActiveRecord::Migration[7.1]
  def change
    add_column :dp_pipelines, :month, :integer
    add_column :dp_pipelines, :year, :integer
    add_index :dp_pipelines, :month
    add_index :dp_pipelines, :year
  end
end
