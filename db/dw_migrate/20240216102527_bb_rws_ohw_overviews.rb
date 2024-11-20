class BbRwsOhwOverviews < ActiveRecord::Migration[7.0]
  def change
    create_table :bb_rws_ohw_overviews do |t|
      t.string    :uid
      t.integer   :account_id
      t.integer   :year
      t.integer   :month
      t.integer   :offer_id
      t.string    :offer_nr
      t.string    :status
      t.string    :deliverable_name
      t.string    :invoice_nr_purchasing
      t.decimal   :amount_purchasing, precision: 10, scale: 2
      t.string    :invoice_nr_sales
      t.date      :invoice_date_sales
      t.decimal   :amount_sales, precision: 10, scale: 2
      t.string    :employee_name
      t.decimal   :hours, precision: 10, scale: 2
      t.decimal   :rate, precision: 10, scale: 2
      t.decimal   :total_employee, precision: 10, scale: 2

      t.timestamps
    end
    add_index :bb_rws_ohw_overviews, [:uid], unique: true
    add_index :bb_rws_ohw_overviews, :account_id
    add_index :bb_rws_ohw_overviews, :year
    add_index :bb_rws_ohw_overviews, :month
    add_index :bb_rws_ohw_overviews, :offer_id
    add_index :bb_rws_ohw_overviews, :status
  end
end