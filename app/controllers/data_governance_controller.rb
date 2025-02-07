class DataGovernanceController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".data_governance.titles.index")]
  end
end
