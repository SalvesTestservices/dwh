class DimDates < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_dates do |t|
      t.integer :year
      t.integer :month
      t.string  :month_name
      t.string  :month_name_short
      t.integer :day
      t.integer :day_of_week
      t.string  :day_name
      t.string  :day_name_short
      t.integer :quarter
      t.integer :week_nr
      t.boolean :is_workday
      t.boolean :is_holiday_nl
      t.boolean :is_holiday_be

      t.timestamps
    end
    add_index :dim_dates, :year
    add_index :dim_dates, :month
    add_index :dim_dates, :day
    add_index :dim_dates, :day_of_week
    add_index :dim_dates, :quarter
    add_index :dim_dates, :week_nr
    add_index :dim_dates, :is_workday
    add_index :dim_dates, :is_holiday_nl
    add_index :dim_dates, :is_holiday_be
  end
end