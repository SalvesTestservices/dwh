class UserMailer < ApplicationMailer
  def account_created(user)
    @user = user
    mail(
      to: @user.email,
      subject: "[Cerios] Je hebt toegang gekregen tot de DWH applicatie"
    )
  end

  def weekly_notifications(receiver_email, account_id, upcoming_data)
    @account = Account.find(account_id)
    @upcoming_data = upcoming_data
    @week_start = Date.current + 7.days
    @week_end = @week_start + 7.days

    mail(
      to: receiver_email,
      subject: "#{@account.name} - Weekoverzicht #{l(@week_start, format: :long)}"
    )
  end
end 