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

      protected

      def cache_key
        parts = [
          'datalab_report',
          @report.id,
          @report.updated_at.to_i,
          Digest::MD5.hexdigest(@params.to_json)
        ]
        
        parts.join('/')
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
    end
  end
end 