module Dwh
  class DimRole < DwhRecord
    validates :role, :category, presence: true
  end
end