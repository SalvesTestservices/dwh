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