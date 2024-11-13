class UsersController < ApplicationController
  def index
    @users = User.all
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