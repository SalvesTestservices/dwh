class UserDecorator < BaseDecorator
  decorates :user

  def role
    case user.role
    when "admin"
      I18n.t(".user.roles.admin")
    when "member"
      I18n.t(".user.roles.member")
    when "viewer"
      I18n.t(".user.roles.viewer")
    when "api"
      I18n.t(".user.roles.api")
    end
  end
end

