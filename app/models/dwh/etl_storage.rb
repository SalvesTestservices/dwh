module Dwh
  class EtlStorage < DwhRecord
    acts_as_tenant(:account)

    validates :identifier, :etl, :data, presence: true
  end
end