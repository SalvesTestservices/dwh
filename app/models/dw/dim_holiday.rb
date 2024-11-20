module Dw
  class DimHoliday < DwRecord
    acts_as_tenant(:account)

    validates :account_id, :holiday_date, :name, :company_id, :country, presence: true
  end
end