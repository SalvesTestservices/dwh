module Datalab
  module Calculators
    class HourCalculator < BaseCalculator
      class << self
        def calculate_month(record)
          activity_date = record.activity_date.to_s
          month = activity_date[-6..-5]
          I18n.t(".date.month_names")[month.to_i]
        end

        def calculate_year(record)
          activity_date = record.activity_date.to_s
          activity_date[-4..-1]
        end
      end
    end
  end
end
