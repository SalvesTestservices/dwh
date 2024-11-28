class DataviewController < ApplicationController
  def index
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".datalab.titles.index")]
  end

  def new
    @available_metrics = QueryBuilder::Base::AVAILABLE_METRICS

  end

  def create
    builder = QueryBuilder::Base.new
    builder.metric(params[:metric])
    builder.time_period(params[:time_period]) if params[:time_period]
    builder.group(params[:group]) if params[:group]
    builder.category(params[:category]) if params[:category]
    
    @result = builder.execute
    session[:last_result] = @result # Store for export
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("result", 
          partial: "result",
          locals: { result: @result }
        )
      end
      format.html { redirect_to new_dataview_path }
    end
  end

  def metric_config
    @metric_type = params[:metric]
    @metric_name = QueryBuilder::Base::AVAILABLE_METRICS[@metric_type.to_sym]
    @metric_options = metric_specific_options(@metric_type)
    @time_period_options = time_period_options

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("nextStep", 
          partial: "metric_config",
          locals: {
            metric_type: @metric_type,
            metric_name: @metric_name,
            metric_options: @metric_options,
            time_period_options: @time_period_options
          }
        )
      end
    end
  end

  def export
    @result = session[:last_result] # We'll store the last result in session
    
    respond_to do |format|
      format.csv do
        send_data generate_csv(@result),
          filename: "report-#{Time.current.strftime('%Y%m%d%H%M%S')}.csv"
      end
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=report-#{Time.current.strftime('%Y%m%d%H%M%S')}.xlsx"
        render xlsx: "export", locals: { result: @result }
      end
      format.pdf do
        send_data generate_pdf(@result),
          filename: "report-#{Time.current.strftime('%Y%m%d%H%M%S')}.pdf"
      end
    end
  end

  private

  def time_period_options
    [
      ['Last 7 days', 'last_7_days'],
      ['Last 30 days', 'last_30_days'],
      ['Last 90 days', 'last_90_days'],
      ['This month', 'this_month'],
      ['Last month', 'last_month'],
      ['Custom range', 'custom']
    ]
  end

  def metric_specific_options(metric_type)
    case metric_type.to_sym
    when :productivity
      { 
        groups: [
          ['Team A', 'team_a'],
          ['Team B', 'team_b'],
          ['Team C', 'team_c']
        ]
      }
    when :revenue
      { 
        categories: [
          ['Category 1', 'cat_1'],
          ['Category 2', 'cat_2'],
          ['Category 3', 'cat_3']
        ]
      }
    when :utilization
      { 
        departments: [
          ['Department 1', 'dept_1'],
          ['Department 2', 'dept_2'],
          ['Department 3', 'dept_3']
        ]
      }
    else
      {}
    end
  end

  def generate_csv(result)
    CSV.generate do |csv|
      csv << ['Metric', 'Value']
      result[:data].each do |key, value|
        csv << [key.to_s.titleize, format_metric_value(key, value)]
      end
    end
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
end
