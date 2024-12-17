module Datalab
  module Calculators
    class BaseCalculator
      class << self
        def calculate_date(date_int)
          return nil if date_int.blank?
          
          date_string = date_int.to_s

          if date_string.size == 7
            day = date_string[0].to_i
            month = date_string[1..2].to_i
            year = date_string[3..6].to_i
          else
            day = date_string[0..1].to_i
            month = date_string[2..3].to_i
            year = date_string[4..7].to_i
          end
          
          Date.new(year, month, day).strftime('%d-%m-%Y')
        end
      end
    end
  end
end