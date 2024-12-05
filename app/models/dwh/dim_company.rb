module Dwh
  class DimCompany < DwhRecord
    validates :account_id, :name, presence: true
  end
end