module Dwh
  class DimHoliday < DwhRecord
    validates :account_id, :holiday_date, :name, :company_id, :country, presence: true
  end
end