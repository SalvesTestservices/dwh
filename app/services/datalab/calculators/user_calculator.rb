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

        def calculate_cost_price(user)
          rate = Dwh::FactRate
            .where(user_id: user.id)
            .order(Arel.sql("
              CAST(
                CASE 
                  WHEN LENGTH(rate_date::text) = 7 
                  THEN CONCAT(SUBSTRING(rate_date::text, 4, 4), '0', SUBSTRING(rate_date::text, 2, 2), '0', SUBSTRING(rate_date::text, 1, 1))
                  ELSE CONCAT(SUBSTRING(rate_date::text, 5, 4), SUBSTRING(rate_date::text, 3, 2), SUBSTRING(rate_date::text, 1, 2))
                END
              AS INTEGER) DESC"))
            .first
          
          format('%.2f', rate.bcr) if rate&.bcr
        end
      end
    end
  end
end
