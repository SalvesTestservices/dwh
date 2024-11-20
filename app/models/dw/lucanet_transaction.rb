module Dw
  class LucanetTransaction < DwRecord
    validates :uid, presence: true
  end
end