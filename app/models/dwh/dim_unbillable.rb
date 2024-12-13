module Dwh
  class DimUnbillable < DwhRecord
    validates :account_id, :original_id, :name, :name_short, presence: true
  end
end