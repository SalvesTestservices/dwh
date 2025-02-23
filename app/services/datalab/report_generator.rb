module Datalab
  class ReportGenerator
    include Pagy::Backend

    def initialize(report, params = {})
      @report = report
      @params = params.with_indifferent_access
      @page = (@params[:page] || 1).to_i
      @items_per_page = (@params[:items_per_page] || 20).to_i
      @anchor_service = AnchorRegistry.get_anchor(@report.anchor_type)[:service]
    end

    def generate
      records, total_count = @anchor_service.fetch_data(
        @params[:filters],
        @page,
        @items_per_page
      )
      
      [records, {
        columns: generate_columns,
        rows: generate_rows(records),
        total_count: total_count,
        current_page: @page,
        items_per_page: @items_per_page
      }]
    end

    private def cache_key
      parts = [
        'datalab_report',
        @report.id,
        @report.updated_at.to_i,
        Digest::MD5.hexdigest(@params.to_json)
      ]
      
      parts.join('/')
    end

    private def generate_report_data(records)
      {
        columns: generate_columns,
        rows: generate_rows(records)
      }
    end

    private def generate_columns
      @report.column_config['columns'].map do |column|
        attribute = @anchor_service.available_attributes[column['id'].to_sym]
        {
          id: column['id'],
          name: attribute[:name],
          sequence: column['sequence']
        }
      end
    end

    private def generate_rows(records)
      records.map do |record|
        row = { id: record.id }
        @report.column_config['columns'].each do |column|
          attribute = @anchor_service.available_attributes[column['id'].to_sym]

          case attribute[:calculation_type]
          when "direct"
            row[column['id']] = record.send(column['id'])
          when "translation"
            value = record.send(attribute[:method])
            row[column['id']] = I18n.t(value, scope: attribute[:translation_scope], default: value)
          when "calculation"
            row[column['id']] = instance_exec(record, &attribute[:calculation])
          when "relation"
            related_model = attribute[:related_model].find_by(id: record.send(column['id']))
            row[column['id']] = related_model&.send(attribute[:display_attribute])
          end
        end
        row
      end
    end
  end
end