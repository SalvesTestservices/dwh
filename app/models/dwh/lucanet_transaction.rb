module Dwh
  class LucanetTransaction < DwhRecord
    validates :uid, presence: true
  end
end