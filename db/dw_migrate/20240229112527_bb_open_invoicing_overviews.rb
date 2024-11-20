class BbOpenInvoicingOverviews < ActiveRecord::Migration[7.0]
  def change
    create_table :bb_open_invoicing_overviews do |t|
      t.string    :uid
      t.integer   :account_id
      t.integer   :company_id
      t.integer   :user_id
      t.integer   :customer_id
      t.integer   :invoice_id
      t.string    :account_name
      t.string    :company_name
      t.string    :user_name
      t.string    :customer_name
      t.string    :project_name
      t.string    :status
      t.string    :category
      t.decimal   :quantity, precision: 10, scale: 2
      t.decimal   :amount, precision: 10, scale: 2

      t.timestamps
    end
    add_index :bb_open_invoicing_overviews , [:uid], unique: true
    add_index :bb_open_invoicing_overviews , :account_id
    add_index :bb_open_invoicing_overviews , :company_id
    add_index :bb_open_invoicing_overviews , :user_id
    add_index :bb_open_invoicing_overviews , :customer_id
    add_index :bb_open_invoicing_overviews , :invoice_id
    add_index :bb_open_invoicing_overviews , :status
    add_index :bb_open_invoicing_overviews , :category
  end
end 