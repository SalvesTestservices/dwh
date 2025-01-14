class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private def user_not_authorized
    flash[:alert] = "Deze pagina bestaat niet."
    redirect_back(fallback_location: root_path)
  end
end
