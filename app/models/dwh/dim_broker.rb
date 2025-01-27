module Dwh
  class DimBroker < DwRecord
    validates :name, presence: true
  end
end