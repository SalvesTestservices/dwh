class UserPolicy < ApplicationPolicy
  def index?
    # Everyone can see the users list
    true 
  end

  def show?
    # Everyone can view user profiles
    true 
  end

  def create?
    # Only admins can create users
    user.admin? 
  end

  def update?
    # Only admins can update users
    user.admin? 
  end

  def destroy?
    # Only admins can delete users
    user.admin? 
  end

  class Scope < Scope
    def resolve
       # Everyone can see all users
      scope.all
    end
  end
end 