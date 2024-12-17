module Datalab
  module Calculators
    class UserCalculator < BaseCalculator
      class << self
        def calculate_start_date(record)
          calculate_date(record.start_date)
        end

        def calculate_leave_date(record)
          calculate_date(record.leave_date)
        end
      end
    end
  end
end
