class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def microsoft_graph
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Microsoft") if is_navigational_format?
    else
      flash[:alert] = "Could not authenticate you from Microsoft. Please contact your administrator."
      redirect_to new_user_session_path
    end
  end

  def failure
    redirect_to root_path, alert: "Failed to authenticate with Microsoft: #{params[:message]}"
  end
end