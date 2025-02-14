class Dg::DataGovernanceController < ApplicationController
  before_action :authenticate_user!
  before_action -> { authorize!(:read, :data_governance) }, only: [:index]

  def index
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".data_governance.titles.index")]
  end
end
