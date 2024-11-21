module Dwh
  class DimAccount < DwhRecord
    validates :original_id, :name, :is_holding, presence: true
  end
end