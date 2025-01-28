module Dwh
  class DimBroker < DwhRecord
    validates :name, presence: true
  end
end