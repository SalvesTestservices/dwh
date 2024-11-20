module Dw
  class DimAccount < DwRecord
    validates :original_id, :name, :is_holding, presence: true
  end
end