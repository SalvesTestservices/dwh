class SiteController < ApplicationController
  before_action :authenticate_user!
  before_action -> { authorize!(:read, :data_api) }, only: [:api_documentation]

  def index
    if current_user.employee?
      redirect_to employee_dashboard_site_index_path
    else
      redirect_to dwh_dashboard_site_index_path
    end
  end

  def dwh_dashboard
    @dg_quality_logs = Dwh::DgQualityLog.where(result: "failed",read_at: nil).order(created_at: :desc)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".site.titles.dashboard")]
  end

  def employee_dashboard    
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".site.titles.dashboard")]
  end

  def api_documentation
    @api_docs = Api::V2::DwhController.api_documentation

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".site.titles.data_api")]
  end
end
