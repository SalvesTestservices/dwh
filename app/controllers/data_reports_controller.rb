class DataReportsController < ApplicationController
  before_action :authenticate_user!

  before_action -> { authorize!(:read, :data_reports) }, only: [:index, :parental_leave]

  def index
    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.data_reports.titles.index')]
  end

  def parental_leave



    
    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.data_reports.titles.index'), data_reports_path]
    @breadcrumbs << [I18n.t('.data_reports.reports.parental_leave')]
  end
end