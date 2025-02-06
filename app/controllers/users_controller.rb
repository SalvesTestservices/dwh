class UsersController < ApplicationController
  def index
    @users = User.order(:first_name)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".user.titles.index"), users_path]
  end

  def show
    @user = User.find(params[:id])

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".user.titles.index"), users_path]
    @breadcrumbs << [I18n.t(".user.titles.show"), user_path(@user)]
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
      redirect_to users_path, notice: I18n.t(".user.messages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".user.titles.index"), users_path]
    @breadcrumbs << [I18n.t(".user.titles.edit")]
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      redirect_to users_path, notice: I18n.t(".user.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])
    
    @user.destroy
    redirect_to users_path, notice: I18n.t(".user.messages.destroyed")
  end

  private def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :role) 
  end
end 