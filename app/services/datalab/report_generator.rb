module Datalab
  class ReportGenerator
    include Pagy::Backend

    def initialize(report, params = {})
      @report = report
      @params = params
    end

    def generate
      generator = generator_class.new(@report, @params)
      records, data = generator.generate

      # Ensure backward compatibility for detail reports
      if @report.report_type == 'detail'
        data[:total_count] ||= records.count
        data[:current_page] ||= (@params[:page] || 1).to_i
        data[:items_per_page] ||= (@params[:items_per_page] || 20).to_i
      end

      [records, data]
    end

    private def generator_class
      case @report.report_type
      when 'group'
        ReportGenerators::GroupGenerator
      else
        ReportGenerators::DetailGenerator
      end
    end
  end
end