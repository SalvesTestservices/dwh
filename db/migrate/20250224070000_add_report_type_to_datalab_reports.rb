class AddReportTypeToDatalabReports < ActiveRecord::Migration[7.1]
  def change
    add_column :datalab_reports, :report_type, :string, default: 'detail'
    add_index :datalab_reports, :report_type
  end
end 