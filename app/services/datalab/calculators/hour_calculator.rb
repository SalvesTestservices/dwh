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

        def calculate_hours_parental_leave(record)
          parental_leave = Dwh::DimUnbillable.find_by(name_short: 'OVB')
          return 0 unless parental_leave&.id == record.unbillable_id

          record.hours
        end
      end
    end
  end
end
