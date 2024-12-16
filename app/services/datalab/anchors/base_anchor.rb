class Datalab::Anchors::BaseAnchor
  class << self
    def available_attributes
      raise NotImplementedError, "#{self.name} must implement available_attributes"
    end

    def fetch_data(column_config)
      raise NotImplementedError, "#{self.name} must implement fetch_data"
    end
  end
end