class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:edit, :update, :destroy]
  
  def index
    @users = User.order(:first_name)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".user.titles.index")]
  end

  def new
    @user = User.new
    
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".user.titles.index"), users_path]
    @breadcrumbs << [I18n.t(".user.titles.new")]
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      UserMailer.account_created(@user).deliver_later
      redirect_to users_path, notice: t(".user.messages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".user.titles.index"), users_path]
    @breadcrumbs << [I18n.t(".user.titles.edit")]
  end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: t(".user.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: t(".user.messages.destroyed"), status: :see_other
  end

  private def set_user
    @user = User.find(params[:id])
  end

  private def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :role)
  end
end 