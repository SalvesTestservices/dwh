module QueryBuilder
  class Base
    attr_reader :steps, :params

    AVAILABLE_METRICS = {
      productivity: 'Productiviteit',
      revenue: 'Omzet',
      utilization: 'Bezetting'
    }.freeze

    def initialize
      @steps = []
      @params = {}
    end

    def metric(type)
      @params[:metric] = type.to_sym
      @steps << [:metric, type]
      self
    end

    def time_period(period)
      @params[:time_period] = period
      @steps << [:time_period, period]
      self
    end

    def group(value)
      @params[:group] = value
      @steps << [:group, value]
      self
    end

    def category(value)
      @params[:category] = value
      @steps << [:category, value]
      self
    end

    def execute
      metric_name = @params[:metric].to_s.classify
      metric_class = "QueryBuilder::Metrics::#{metric_name}".constantize
      metric_class.new(@params).execute
    end
  end
end
