class SiteController < ApplicationController
  before_action :authenticate_user!
  before_action -> { authorize!(:read, :data_api) }, only: [:api_documentation]

  def index
    @dg_quality_logs = Dwh::DgQualityLog.where(result: "failed",read_at: nil).order(created_at: :desc)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".site.titles.dashboard")]
  end

  def api_documentation
    @api_docs = Api::V2::DwhController.api_documentation

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".site.titles.data_api")]
  end
end
