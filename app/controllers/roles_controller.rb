class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_role, only: [:edit, :update, :destroy]
  
  before_action -> { authorize!(:read, :roles) }, only: [:index]
  before_action -> { authorize!(:write, :roles) }, only: [:new, :create, :edit, :update]
  before_action -> { authorize!(:delete, :roles) }, only: [:destroy]

  def index
    @roles = Role.order(:name)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".role.titles.index"), roles_path]
  end

  def new
    @role = Role.new

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".role.titles.index"), roles_path]
    @breadcrumbs << [I18n.t(".role.titles.new")]
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      redirect_to roles_path, notice: I18n.t(".role.messages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".role.titles.index"), roles_path]
    @breadcrumbs << [I18n.t(".role.titles.edit")]
  end

  def update
    if @role.update(role_params)
      redirect_to roles_path, notice: I18n.t(".role.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @role.destroy
    redirect_to roles_path, notice: I18n.t(".role.messages.destroyed")
  end

  private def set_role
    @role = Role.find(params[:id])
  end

  private def role_params
    params.require(:role).permit(:name, :key, permissions: [])
  end
end 