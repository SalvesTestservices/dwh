module Dwh
  class DimProject < DwhRecord
    validates :account_id, :original_id, :name, :status, :calculation_type, presence: true
  end
end