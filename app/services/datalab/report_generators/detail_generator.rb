module Datalab
  module ReportGenerators
    class DetailGenerator < BaseGenerator
      def generate
        records, total_count = @anchor_service.fetch_data(
          @params[:filters],
          @page,
          @items_per_page
        )
        
        [records, {
          columns: generate_columns,
          rows: generate_detail_rows(records),
          total_count: total_count,
          current_page: @page,
          items_per_page: @items_per_page
        }]
      end

      private def generate_detail_rows(records)
        records.map do |record|
          row = {}
          @report.column_config['columns'].each do |column|
            attribute = @anchor_service.available_attributes[column['id'].to_sym]
            row[column['id']] = calculate_field_value(record, column, attribute)
          end
          row
        end
      end

      def calculate_field_value(record, column, attribute)
        return nil if attribute.nil?

        case attribute[:calculation_type]
        when "direct"
          record.send(column['id'])
        when "translation"
          value = record.send(attribute[:method])
          I18n.t(value, scope: attribute[:translation_scope], default: value)
        when "calculation"
          instance_exec(record, &attribute[:calculation])
        when "relation"
          related_record = attribute[:related_model].find_by(id: record.send(column['id']))
          related_record&.send(attribute[:display_attribute])
        else
          record.send(column['id'])
        end
      end
    end
  end
end 