class DataOverviewsController < ApplicationController
  before_action :authenticate_user!

  before_action -> { authorize!(:read, :employee_overviews) }, only: [:bonus_overview]

  def bonus_overview
  end
end