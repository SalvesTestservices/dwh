class AddGroupingToDatalabReports < ActiveRecord::Migration[7.0]
  def change
    add_column :datalab_reports, :grouping_options, :jsonb, default: {}
    add_index :datalab_reports, :grouping_options, using: :gin
  end
end 