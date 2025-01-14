class UserMailer < ApplicationMailer
  def account_created(user)
    @user = user
    mail(
      to: @user.email,
      subject: "[Cerios] Je hebt toegang gekregen tot de DWH applicatie"
    )
  end
end 