module Datalab
  module Calculators
    class HourCalculator < BaseCalculator
      class << self
        def calculate_hours_gvp(record)
          10
        end

        def calculate_hours_agvp(record)
          10
        end

        def calculate_hours_ovb(record)
          10
        end

        def calculate_hours_ovo(record)
          10
        end

        def calculate_hours_apv(record)
          10
        end
      end
    end
  end
end
