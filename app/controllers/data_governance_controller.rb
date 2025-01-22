class DataGovernanceController < ApplicationController
  def index
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".data_governance.titles.index")]
  end
end
