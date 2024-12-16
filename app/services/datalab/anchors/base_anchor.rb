module Datalab
  module Anchors
    class BaseAnchor
      class << self
        def available_attributes
          raise NotImplementedError
        end

        def filterable_attributes
          []
        end

        def sortable_attributes
          []
        end

        def apply_filter(records, field, value)
          records
        end

        def apply_sorting(records, field, direction)
          records
        end

        def fetch_data(column_config)
          raise NotImplementedError
        end
      end
    end
  end
end