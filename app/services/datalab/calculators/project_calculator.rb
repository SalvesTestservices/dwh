module Datalab
  module Calculators
    class ProjectCalculator < BaseCalculator
      class << self
        def calculate_start_date(record)
          calculate_date(record.start_date)
        end

        def calculate_end_date(record)
          calculate_date(record.end_date)
        end

        def calculate_expected_end_date(record)
          calculate_date(record.expected_end_date)
        end
      end
    end
  end
end
