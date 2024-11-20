class BbInvoiceOverviews < ActiveRecord::Migration[7.0]
  def change
    create_table :bb_invoice_overviews do |t|
      t.string    :uid
      t.integer   :account_id
      t.integer   :company_id
      t.integer   :user_id
      t.integer   :customer_id
      t.integer   :invoice_id
      t.integer   :project_id
      t.string    :account_name
      t.string    :company_name
      t.string    :invoice_nr
      t.date      :invoice_date
      t.string    :invoice_type
      t.integer   :month
      t.integer   :year
      t.string    :user_name
      t.string    :customer_name
      t.string    :project_name
      t.string    :description
      t.decimal   :quantity, precision: 10, scale: 2
      t.decimal   :amount, precision: 10, scale: 2

      t.timestamps
    end
    add_index :bb_invoice_overviews , [:uid], unique: true
    add_index :bb_invoice_overviews , :account_id
    add_index :bb_invoice_overviews , :company_id
    add_index :bb_invoice_overviews , :user_id
    add_index :bb_invoice_overviews , :customer_id
    add_index :bb_invoice_overviews , :invoice_id
    add_index :bb_invoice_overviews , :project_id
    add_index :bb_invoice_overviews , :month
    add_index :bb_invoice_overviews , :year
    add_index :bb_invoice_overviews , :invoice_date
    add_index :bb_invoice_overviews , :invoice_nr
    add_index :bb_invoice_overviews , :invoice_type
  end
end 