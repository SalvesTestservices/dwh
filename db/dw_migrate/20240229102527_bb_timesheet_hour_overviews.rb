class BbTimesheetHourOverviews < ActiveRecord::Migration[7.0]
  def change
    create_table :bb_timesheet_hour_overviews do |t|
      t.string    :uid
      t.integer   :account_id
      t.integer   :company_id
      t.integer   :user_id
      t.integer   :customer_id
      t.integer   :unbillable_id
      t.integer   :month
      t.integer   :year
      t.integer   :day
      t.string    :account_name
      t.string    :company_name
      t.string    :user_name
      t.string    :customer_name
      t.string    :project_name
      t.string    :unbillable_name
      t.decimal   :hours, precision: 10, scale: 2
      t.decimal   :rate, precision: 10, scale: 2
      t.decimal   :purchase_price, precision: 10, scale: 2

      t.timestamps
    end
    add_index :bb_timesheet_hour_overviews , [:uid], unique: true
    add_index :bb_timesheet_hour_overviews , :account_id
    add_index :bb_timesheet_hour_overviews , :company_id
    add_index :bb_timesheet_hour_overviews , :user_id
    add_index :bb_timesheet_hour_overviews , :customer_id
    add_index :bb_timesheet_hour_overviews , :unbillable_id
    add_index :bb_timesheet_hour_overviews , :month
    add_index :bb_timesheet_hour_overviews , :year
  end
end 