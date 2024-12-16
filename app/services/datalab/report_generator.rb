class Datalab::ReportGenerator
  def initialize(report, params = {})
    @report = report
    @params = params
    @calculator = Calculator.new(@report.anchor_type)
    @anchor_service = AnchorRegistry.get_anchor(@report.anchor_type)[:service]
  end

  def generate
    records = fetch_records
    records = apply_filters(records)
    records = apply_sorting(records)
    generate_report_data(records)
  end

  private

  def apply_filters(records)
    return records unless @params[:filters]

    @params[:filters].each do |field, value|
      next if value.blank?

      if @anchor_service.filterable_attributes.include?(field.to_sym)
        records = @anchor_service.apply_filter(records, field, value)
      end
    end
    
    records
  end

  def apply_sorting(records)
    return records unless @params[:sort_by].present?

    field = @params[:sort_by]
    direction = @params[:sort_direction] || 'asc'

    if @anchor_service.sortable_attributes.include?(field.to_sym)
      @anchor_service.apply_sorting(records, field, direction)
    else
      records
    end
  end

  def fetch_records
    column_ids = @report.column_config['columns'].map { |c| c['id'] }
    @anchor_service.fetch_data(column_ids)
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
        row[column['id']] = @calculator.calculate_for_record(record, column['id'])
      end
      row
    end
  end
end
