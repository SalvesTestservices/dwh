class DataTargetsController < ApplicationController
  before_action :authenticate_user!

  def index
    @data_targets = DataTarget.where(company_id: params[:company_id]) if params[:company_id].present?
    @year = params[:year] || Date.current.year
    
    @account_companies = Dwh::DimCompany
      .joins("INNER JOIN dim_accounts ON dim_companies.account_id = dim_accounts.id")
      .select('dim_companies.*, dim_accounts.name as account_name')
      .order('dim_accounts.name, dim_companies.name')

    #@current_quarter = Date.current.quarter
    #@data_targets = @company.company_targets.where(year: @year, quarter: @current_quarter).order(:month)
    #@year_target = @company.company_targets.find_by(year: @year, month: 1, role: "employee")

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.data_target.titles.index')]
  end

  def update
    @data_target = DataTarget.find(params[:id])

    params[:data_target][:fte] = 0 if params[:data_target][:fte] == ""
    params[:data_target][:billable_hours] = 0 if params[:data_target][:billable_hours] == ""
    params[:data_target][:bruto_margin] = 0 if params[:data_target][:bruto_margin] == ""
    params[:data_target][:cost_price] = 0 if params[:data_target][:cost_price] == ""

    if @data_target.update(data_target_params)
      set_totals(@data_target)
      update_all_targets(@data_target)
    else
      render action: "edit", status: 422
    end
  end

  private def set_totals(data_target)
    all_data_targets = DataTarget.where(company_id: data_target.company_id, year: data_target.year, role: data_target.role)

    @nr_months_filled = 0
    @total_productivity = 0.0
    @total_hour_rate = 0.0
    @total_fte_delta = 0.0
    @total_turnover = 0.0
    all_data_targets.each do |data_target|
      @nr_months_filled += 1 if data_target.fte > 0
      @total_productivity += data_target.productivity(false)
      @total_hour_rate += data_target.hour_rate(false)
      @total_fte_delta += data_target.fte_delta
      @total_turnover += data_target.turnover(false)
    end

    @total_billable_hours = all_data_targets.sum(:billable_hours)
    @total_bruto_margin = all_data_targets.sum(:bruto_margin)
    @total_cost_price = all_data_targets.sum(:cost_price)
  end

  private def update_all_targets(target)
    if target.month == 1 and target.role == "employee"
      data_targets = DataTarget.where(company_id: target.company_id, year: target.year)
      unless data_targets.blank?
        data_targets.each do |data_target|
          data_target.update(employee_attrition: target.employee_attrition, employee_absence: target.employee_absence)
        end
      end
    end
  end

  private def data_target_params
    params.require(:data_target).permit(:company_id, :year, :month, :role, :fte, :billable_hours, :cost_price, :bruto_margin, :employee_attrition, :employee_absence)
  end
end