module Dwh
  class EtlStorage < DwhRecord
    validates :identifier, :etl, :data, presence: true
  end
end