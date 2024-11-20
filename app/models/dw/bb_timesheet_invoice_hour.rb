class Dw::BbTimesheetInvoiceHour < DwRecord
  acts_as_tenant(:account)

  validates :uid, :month, :year, :account_id, :account_name, :company_name, :user_name, :customer_name, :timesheet_hours, :invoice_hours, :diff_hours, presence: true
end