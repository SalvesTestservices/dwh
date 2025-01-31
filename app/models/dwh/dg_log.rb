class Dwh::DgLog < DwhRecord
  validates :object_id, :object_type, :action, :status, presence: true
end