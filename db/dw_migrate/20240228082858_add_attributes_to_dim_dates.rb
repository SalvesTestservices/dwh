class AddAttributesToDimDates < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_dates, :original_date, :date
    add_column :dim_dates, :yearmonth, :integer
    add_column :dim_dates, :iso_year, :integer
    add_column :dim_dates, :iso_week, :integer
    add_index :dim_dates, :original_date
    add_index :dim_dates, :yearmonth
    add_index :dim_dates, :iso_year
    add_index :dim_dates, :iso_week
  end
end
