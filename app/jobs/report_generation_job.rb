class ReportGenerationJob < ApplicationJob
  queue_as :default

  def perform(result_id, format, user_id)
    result = Rails.cache.read("report_result_#{result_id}")
    user = User.find(user_id)
    
    case format.to_sym
    when :csv
      data = generate_csv(result)
      filename = "report-#{Time.current.strftime('%Y%m%d%H%M%S')}.csv"
      content_type = 'text/csv'
    when :xlsx
      data = generate_excel(result)
      filename = "report-#{Time.current.strftime('%Y%m%d%H%M%S')}.xlsx"
      content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    when :pdf
      data = generate_pdf(result)
      filename = "report-#{Time.current.strftime('%Y%m%d%H%M%S')}.pdf"
      content_type = 'application/pdf'
    end

    # Create report record
    report = Report.create!(
      user: user,
      filename: filename,
      format: format,
      status: 'completed'
    )

    # Attach the generated file
    report.file.attach(
      io: StringIO.new(data),
      filename: filename,
      content_type: content_type
    )

    # Send notification email
    ReportMailer.completion_notification(report).deliver_now
  end

  private

  def generate_csv(result)
    CSV.generate do |csv|
      csv << ['Metric', 'Value']
      result[:data].each do |key, value|
        csv << [key.to_s.titleize, format_metric_value(key, value)]
      end
    end
  end

  def generate_excel(result)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Report") do |sheet|
      sheet.add_row ['Metric', 'Value']
      result[:data].each do |key, value|
        sheet.add_row [key.to_s.titleize, format_metric_value(key, value)]
      end
    end
    package.to_stream.read
  end

  def generate_pdf(result)
    pdf = Prawn::Document.new
    pdf.text result[:title], size: 20, style: :bold
    pdf.move_down 20
    
    data = [['Metric', 'Value']]
    result[:data].each do |key, value|
      data << [key.to_s.titleize, format_metric_value(key, value)]
    end
    
    pdf.table(data, header: true, width: pdf.bounds.width)
    pdf.render
  end

  def format_metric_value(key, value)
    case
    when value.is_a?(Numeric) && key.to_s.include?('rate')
      "#{value}%"
    when value.is_a?(Numeric) && key.to_s.include?('revenue')
      "€#{value}"
    when value.is_a?(Numeric) && key.to_s.include?('hours')
      "#{value} hours"
    else
      value.to_s
    end
  end
end
