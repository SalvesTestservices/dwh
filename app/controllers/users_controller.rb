class UsersController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @users = User.order(:first_name)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".user.titles.index")]
  end

  def invite
    user = User.invite!({ email: params[:email] }, current_user)
    if user.errors.empty?
      flash[:notice] = "User has been successfully invited."
    else
      flash[:alert] = user.errors.full_messages.join(", ")
    end
    redirect_to users_path
  end
end 