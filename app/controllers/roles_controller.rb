class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_role, only: [:edit, :update, :destroy]
  
  before_action -> { authorize!(:write, :roles) }, only: [:new, :create, :edit, :update]
  before_action -> { authorize!(:delete, :roles) }, only: [:destroy]

  def new
    @role = Role.new

    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".site.titles.users_and_roles"), users_path(view: "roles")]
    @breadcrumbs << [I18n.t(".role.titles.new")]
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      redirect_to roles_path, notice: 'Role was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @breadcrumbs = []
    @breadcrumbs << [I18n.t(".site.titles.users_and_roles"), users_path(view: "roles")]
    @breadcrumbs << [I18n.t(".role.titles.edit")]
  end

  def update
    if @role.update(role_params)
      redirect_to users_path(view: "roles"), notice: 'Role was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @role.destroy
    redirect_to users_path(view: "roles"), notice: 'Role was successfully deleted.'
  end

  private def set_role
    @role = Role.find(params[:id])
  end

  private def role_params
    params.require(:role).permit(:name, permissions: [])
  end
end 