module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :can?
  end

  def can?(action, resource)
    AuthorizationChecker.can?(current_user, action, resource)
  end

  def authorize!(action, resource)
    unless can?(action, resource)
      flash[:error] = "You are not authorized to perform this action."
      redirect_to root_path
    end
  end
end 