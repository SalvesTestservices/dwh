class AddCompanyIdToTimesheetHours < ActiveRecord::Migration[7.1]
  def change
    add_column :bb_timesheet_invoice_hours, :company_id, :integer
    add_index :bb_timesheet_invoice_hours, :company_id
  end
end
