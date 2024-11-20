class BbGroupedWorkOverviews < ActiveRecord::Migration[7.0]
  def change
    create_table :bb_grouped_work_overviews do |t|
      t.bigint    :uid
      t.integer   :account_id
      t.integer   :company_id
      t.integer   :user_id
      t.integer   :customer_id
      t.integer   :project_id
      t.integer   :timesheet_id
      t.integer   :projectuser_id
      t.integer   :invoice_id
      t.integer   :month
      t.integer   :year
      t.string    :account_name
      t.string    :company_name
      t.string    :target
      t.string    :group
      t.string    :row_type
      t.string    :user_name
      t.string    :customer_name
      t.string    :project_name
      t.string    :broker
      t.date      :start_date
      t.date      :end_date
      t.string    :calculation_type
      t.string    :hour_type
      t.decimal   :hours, precision: 10, scale: 2
      t.decimal   :rate, precision: 10, scale: 2
      t.jsonb     :invoices, default: {}
      t.jsonb     :progress, default: {}
      t.string    :frequence
      t.string    :type_amount
      t.decimal   :period_amount, precision: 10, scale: 2
      t.boolean   :credit
      t.string    :status
      t.date      :invoice_date
      t.decimal   :turnover_excl_vat, precision: 10, scale: 2
      t.decimal   :vat, precision: 10, scale: 2
      t.decimal   :turnover_incl_vat, precision: 10, scale: 2

      t.timestamps
    end
    add_index :bb_grouped_work_overviews, [:uid], unique: true
    add_index :bb_grouped_work_overviews, :account_id
    add_index :bb_grouped_work_overviews, :company_id
    add_index :bb_grouped_work_overviews, :user_id
    add_index :bb_grouped_work_overviews, :customer_id
    add_index :bb_grouped_work_overviews, :project_id
    add_index :bb_grouped_work_overviews, :timesheet_id
    add_index :bb_grouped_work_overviews, :projectuser_id
    add_index :bb_grouped_work_overviews, :invoice_id
    add_index :bb_grouped_work_overviews, :month
    add_index :bb_grouped_work_overviews, :year
    add_index :bb_grouped_work_overviews, :target
    add_index :bb_grouped_work_overviews, :group
  end
end 