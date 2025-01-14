class UsersController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @users = User.order(:first_name)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".user.titles.index")]
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      UserMailer.account_created(@user).deliver_later
      flash[:notice] = "User has been successfully created."
    else
      flash[:alert] = @user.errors.full_messages.join(", ")
    end
    redirect_to users_path
  end

  private def user_params
    params.require(:user).permit(:email, :first_name, :last_name)
  end
end 