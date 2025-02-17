class NotificationSender
  def initialize
    @accounts = Account.all
    @start_date = Date.current + 7.days
    @end_date = @start_date + 7.days
  end

  def send_notifications
    # Only run on Mondays
    return unless DateTime.now.wday == 1

    # Set the notification receivers for each account
    notification_receivers = {
      'QDat' => ['monique@deagiletesters.nl'],
      'Salves' => ['diana.van.raamsdonk@salves.nl', 'sigrid.van.lieshout@salves.nl'],
      'Test Crew IT' => ['jolijn.mertens@testcrew-it.nl'],
      'Valori' => ['kellyberends@valori.nl'],
      'Cerios' => ['rianne.van.de.water@cerios.nl', 'nicky.hovens@cerios.nl']
    }

    # Process each account
    ActsAsTenant.without_tenant do
      @accounts.each do |account|
        # Skip if the account is not in the notification receivers list
        next unless notification_receivers[account.name]

        # Collect the upcoming data for the account
        upcoming_data = {
          birthdays: collect_birthdays(account),
          jubilees: collect_jubilees(account),
          passport_expirations: collect_passport_expirations(account)
        }

        # Send the notifications to the receivers
        notification_receivers[account.name].each do |receiver_email|
          UserMailer.weekly_notifications(
            receiver_email,
            account,
            upcoming_data
          ).deliver_later
        end
      end
    end
  end

  private def collect_birthdays(account)
    dates = (@start_date ... @end_date).map { |d| d.strftime('%m%d') }
    dates << '0229' if dates.include?('0228')
    
    account.users
          .where("role != 'external'")
          .where("to_char(birth_date, 'MMDD') in (?)", dates)
          .order("to_char(birth_date, 'MMDD')")
          .map { |user| "#{user.birth_date.strftime('%d-%m')}: #{user.full_name}" }
  end

  private def collect_jubilees(account)
    jubilee_dates = [
      { years: 15, weeks: 5 },  # 5 weeks to look at next week's jubilees
      { years: 10, weeks: 5 },
      { years: 5, weeks: 5 }
    ]

    users = account.users.employed.where("role != 'external'")
    jubilee_users = []

    users.each do |user|
      next unless user.start_date.present?

      jubilee_dates.each do |jubilee|
        if user.start_date.to_date == (jubilee[:years].years.ago + jubilee[:weeks].weeks).to_date
          jubilee_users << "#{user.start_date.strftime('%d-%m')}: #{user.full_name} (#{jubilee[:years]} jaar)"
        end
      end
    end

    jubilee_users
  end

  private def collect_passport_expirations(account)
    account.users
          .employed
          .where("role != 'external'")
          .where.not(expiration_date_passport: nil)
          .where(expiration_date_passport: @start_date..@end_date)
          .order(:expiration_date_passport)
          .map { |user| "#{user.expiration_date_passport.strftime('%d-%m')}: #{user.full_name}" }
  end
end
