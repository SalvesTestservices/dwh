class EmployeesController < ApplicationController
  before_action :authenticate_user!

  before_action -> { authorize!(:read, :employees) }, only: [:index, :show]

  def index
    @employees = Dwh::DimUser.where(role: "employee").order(:full_name)

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