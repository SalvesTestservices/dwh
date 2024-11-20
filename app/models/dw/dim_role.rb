module Dw
  class DimRole < DwRecord
    validates :role, :category, presence: true
  end
end