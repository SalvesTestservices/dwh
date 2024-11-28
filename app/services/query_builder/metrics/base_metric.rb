module QueryBuilder
  module Metrics
    class BaseMetric
      def initialize(params)
        @params = params
      end

      def execute
        raise NotImplementedError, "#{self.class} must implement #execute"
      end
    end
  end
end