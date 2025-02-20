class AddReportTypeDatalabReports < ActiveRecord::Migration[8.0]
  def change
    add_column :datalab_reports, :report_type, :string, default: 'rows'
    add_index :datalab_reports, :report_type
  end
end
