module Dwh
  class DimCustomer < DwhRecord
    validates :name, :status, :original_id, :account_id, presence: true
  end
end