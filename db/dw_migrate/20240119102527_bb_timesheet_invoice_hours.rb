class BbTimesheetInvoiceHours < ActiveRecord::Migration[7.0]
  def change
    create_table :bb_timesheet_invoice_hours do |t|
      t.bigint    :uid
      t.integer   :account_id
      t.integer   :month
      t.integer   :year
      t.string    :account_name
      t.string    :company_name
      t.string    :user_name
      t.string    :customer_name
      t.decimal   :timesheet_hours, precision: 10, scale: 2
      t.decimal   :invoice_hours, precision: 10, scale: 2
      t.decimal   :diff_hours, precision: 10, scale: 2

      t.timestamps
    end
    add_index :bb_timesheet_invoice_hours, [:uid], unique: true
    add_index :bb_timesheet_invoice_hours, :account_id
    add_index :bb_timesheet_invoice_hours, :month
    add_index :bb_timesheet_invoice_hours, :year
  end
end