class Api::V2::BaseController < ApplicationController
  before_action :set_default_format
  before_action :authenticate_user

  def execute_query(sql)
    result = DwhRecord.connection.execute(sql)
  end

  private def authenticate_user
    user = User.find_by(email: params[:email])
    if user.present? and user.valid_password?(params[:password])
      @current_user = user
    else
      render json: { errors: ["Invalid email or password"] }
    end
  end

  private def set_default_format
    request.format = :json
  end
end
