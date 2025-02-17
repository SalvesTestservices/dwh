class UserMailer < ApplicationMailer
  def account_created(user)
    @user = user
    mail(
      to: @user.email,
      subject: "[Cerios] Je hebt toegang gekregen tot de DWH applicatie"
    )
  end

  def weekly_notifications(receiver_email, account, upcoming_data)
    @account = account
    @birthdays = upcoming_data[:birthdays]
    @jubilees = upcoming_data[:jubilees]
    @passport_expirations = upcoming_data[:passport_expirations]
    @week_start = Date.current + 7.days
    @week_end = @week_start + 6.days

    mail(
      to: receiver_email,
      subject: "#{account.name} - Weekly Notifications (#{@week_start.strftime('%d-%m')} - #{@week_end.strftime('%d-%m')})"
    )
  end
end 