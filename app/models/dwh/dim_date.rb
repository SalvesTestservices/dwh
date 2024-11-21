module Dwh
  class DimDate < DwhRecord
    validates :year, :month, :month_name, :month_name_short, :day, :day_of_week, :day_name, :day_name_short, :quarter, :week_nr, presence: true
  end
end