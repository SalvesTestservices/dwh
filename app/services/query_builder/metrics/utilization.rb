module QueryBuilder
  module Metrics
    class Utilization < BaseMetric
      def execute
        {
          title: "Utilization Report",
          time_period: format_time_period(@params[:time_period]),
          department: @params[:department],
          data: sample_data
        }
      end

      private

      def format_time_period(period)
        case period
        when 'last_7_days' then 'Last 7 Days'
        when 'last_30_days' then 'Last 30 Days'
        when 'this_month' then 'This Month'
        else period.to_s.humanize
        end
      end

      def sample_data
        {
          utilization_rate: 78,
          available_hours: 240,
          billable_hours: 187,
          trend: 'stable'
        }
      end
    end
  end
end
