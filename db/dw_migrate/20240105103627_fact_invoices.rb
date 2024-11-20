class FactInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_invoices do |t|
      t.integer :account_id
      t.integer :original_id
      t.integer :invoice_date
      t.string  :status
      t.integer :project_id
      t.integer :customer_id
      t.integer :user_id
      t.integer :company_id
      t.integer :timesheet_month
      t.integer :timesheet_year
      t.boolean :credit
      t.integer :condition_days
      t.boolean :internal_charging
      t.decimal :amount_excl_vat, precision: 10, scale: 2
      t.decimal :vat_6, precision: 10, scale: 2
      t.decimal :vat_9, precision: 10, scale: 2
      t.decimal :vat_21, precision: 10, scale: 2
      t.decimal :vat_total, precision: 10, scale: 2
      t.decimal :amount_incl_vat, precision: 10, scale: 2

      t.timestamps
    end
    add_index :fact_invoices, [:account_id, :original_id], unique: true
    add_index :fact_invoices, :invoice_date
    add_index :fact_invoices, :status
    add_index :fact_invoices, :project_id
    add_index :fact_invoices, :customer_id
    add_index :fact_invoices, :user_id
    add_index :fact_invoices, :company_id
    add_index :fact_invoices, :timesheet_month
    add_index :fact_invoices, :timesheet_year
    add_index :fact_invoices, :credit
    add_index :fact_invoices, :condition_days
    add_index :fact_invoices, :internal_charging
  end
end
