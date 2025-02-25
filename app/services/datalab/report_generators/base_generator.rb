module Datalab
  module ReportGenerators
    class BaseGenerator
      include Pagy::Backend

      def initialize(report, params = {})
        @report = report
        @params = params.with_indifferent_access
        @page = (@params[:page] || 1).to_i
        @items_per_page = (@params[:items_per_page] || 20).to_i
        @anchor_service = AnchorRegistry.get_anchor(@report.anchor_type)[:service]
      end

      def generate_columns
        @report.column_config['columns'].map do |column|
          attribute = @anchor_service.available_attributes[column['id'].to_sym]
          {
            id: column['id'],
            name: attribute[:name],
            sequence: column['sequence']
          }
        end
      end

      def extract_month(original_date)
        original_date_str = original_date.to_s
        if original_date_str.length == 7
          original_date_str[1..2]  # For 7-digit format
        else
          original_date_str[2..3]  # For 8-digit format (DDMMYYYY)
        end
      end

      def extract_year(original_date)
        original_date_str = original_date.to_s
        if original_date_str.length == 7
          original_date_str[4..7]  # For 7-digit format
        else
          original_date_str[5..8]  # For 8-digit format (DDMMYYYY)
        end
      end
    end
  end
end 