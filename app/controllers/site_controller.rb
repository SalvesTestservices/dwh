class SiteController < ApplicationController
  before_action :authenticate_user!
  before_action -> { authorize!(:read, :data_api) }, only: [:api_documentation]

  def index
  end

  def api_documentation
    @api_docs = Api::V2::DwhController.api_documentation

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".site.titles.data_api")]
  end
end
