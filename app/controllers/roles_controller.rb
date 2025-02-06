class RolesController < ApplicationController
  before_action :authorize!(:read, :roles), only: [:index, :show]
  before_action :authorize!(:write, :roles), only: [:new, :create, :edit, :update]
  before_action :authorize!(:delete, :roles), only: [:destroy]
  before_action :set_role, only: [:edit, :update, :destroy]

  def index
    @roles = Role.all
  end

  def new
    @role = Role.new
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
  end

  def update
    if @role.update(role_params)
      redirect_to roles_path, notice: 'Role was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @role.destroy
    redirect_to roles_path, notice: 'Role was successfully deleted.'
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, permissions: [])
  end
end 