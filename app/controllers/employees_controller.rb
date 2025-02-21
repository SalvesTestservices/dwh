class EmployeesController < ApplicationController
  before_action :authenticate_user!

  before_action -> { authorize!(:read, :employees) }, only: [:index, :show]

  def index
    @user_emails = User.all.pluck(:email)
    
    @query = params[:query]    
    if @query.present?
      @search_results = PgSearch.multisearch(@query)
      
      # Get users directly matching the search
      user_ids_from_name = @search_results
        .where(searchable_type: 'Dwh::DimUser')
        .pluck(:searchable_id)
      
      # Get account_ids from matching account names
      account_ids = @search_results
        .where(searchable_type: 'Dwh::DimAccount')
        .pluck(:searchable_id)
      
      # Get company_ids from matching company names
      company_ids = @search_results
        .where(searchable_type: 'Dwh::DimCompany')
        .pluck(:searchable_id)
      
      @dim_users = Dwh::DimUser
        .where(email: @user_emails)
        .where('dim_users.id IN (?) OR dim_users.account_id IN (?) OR dim_users.company_id IN (?)', user_ids_from_name, account_ids, company_ids)
        .order(:full_name)
    else
      @dim_users = Dwh::DimUser.where(email: @user_emails).order(:full_name)
    end

    @dim_accounts = Dwh::DimAccount.all
    @dim_companies = Dwh::DimCompany.all

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".employee.titles.index"), employees_path]
  end

  def show
    @employee = Dwh::DimUser.find(params[:id])

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".employee.titles.index"), employees_path]
    @breadcrumbs << [I18n.t(".employee.titles.show"), employee_path(@employee)]
  end
end 