class DwhRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :dwh, reading: :dwh }
end
