class DataOverviewsController < ApplicationController
  before_action :authenticate_user!

  before_action -> { authorize!(:read, :employee_overviews) }, only: [:bonus_overview]

  def bonus_overview
    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.data_overview.titles.bonus_overview')]
  end

  def holiday_overview
    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.data_overview.titles.holiday_overview')]
  end

  def children_leave_overview
    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.data_overview.titles.children_leave_overview')]
  end
end