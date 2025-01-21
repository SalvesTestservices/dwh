module Datalab
  class ReportGenerator
    include Pagy::Backend

    def initialize(report, params = {}, limit)
      @report = report
      @params = params
      @limit = limit
      @anchor_service = AnchorRegistry.get_anchor(@report.anchor_type)[:service]
    end

    def generate
      records = fetch_records
      records = apply_filters(records)
      records = apply_sorting(records)
      
      # Return the records for pagination in the controller
      [records, {
        columns: generate_columns,
        rows: generate_rows(records)
      }]
    end

    private

    def cache_key
      parts = [
        'datalab_report',
        @report.id,
        @report.updated_at.to_i,
        Digest::MD5.hexdigest(@params.to_json)
      ]
      
      parts.join('/')
    end

    def apply_filters(records)
      filters = @params[:filters]
      return records if filters.blank?

      filters.to_unsafe_h.each do |field, values|
        next if values.blank?
        
        # Handle array of arrays from params (e.g., [["5"], ["2"]])
        values = values.flatten.reject(&:blank?)
        next if values.empty?
        
        records = @anchor_service.apply_filter(records, field, values)
      end

      records
    end

    def apply_sorting(records)
      @anchor_service.apply_sorting(records)
    end

    def fetch_records
      @anchor_service.fetch_data(@limit, @report.column_config['columns'].map { |c| c['id'] })
    end

    def generate_report_data(records)
      {
        columns: generate_columns,
        rows: generate_rows(records)
      }
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

    def generate_rows(records)
      records.map do |record|
        row = { id: record.id }
        @report.column_config['columns'].each do |column|
          attribute = @anchor_service.available_attributes[column['id'].to_sym]

          case attribute[:calculation_type]
          when "direct"
            row[column['id']] = record.send(column['id'])
          when "translation"
            row[column['id']] = record.send(attribute[:method])
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