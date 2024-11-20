module Dw
  class EtlStorage < DwRecord
    acts_as_tenant(:account)

    validates :identifier, :etl, :data, presence: true
  end
end