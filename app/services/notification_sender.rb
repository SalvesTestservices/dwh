class NotificationSender
  def initialize
    @accounts = Account.all
    @start_date = Date.current + 7.days
    @end_date = @start_date + 7.days
  end

  def send_notifications
    # Only run on Mondays
    #return unless DateTime.now.wday == 1

    # Set the notification receivers for each account
    notification_receivers = {
      'QDat' => ['monique@deagiletesters.nl'],
      'Salves' => ['diana.van.raamsdonk@salves.nl', 'sigrid.van.lieshout@salves.nl'],
      'Test Crew IT' => ['jolijn.mertens@testcrew-it.nl'],
      'Valori' => ['kellyberends@valori.nl'],
      'Cerios' => ['rianne.van.de.water@cerios.nl', 'nicky.hovens@cerios.nl']
    }

    # Process each account
    @accounts.each do |account|
      puts "ACCOUNT: #{account.name}"
      # Skip if the account is not in the notification receivers list
      next unless notification_receivers[account.name]
puts "JA"
      # Collect the upcoming data for the account
      upcoming_data = {
        birthdays: collect_birthdays(account)
        #jubilees: collect_jubilees(account)
      }
puts "JA2 #{upcoming_data}"
      # Send the notifications to the receivers
      notification_receivers[account.name].each do |receiver_email|
        puts "JA3 #{receiver_email}"
        UserMailer.weekly_notifications(
          receiver_email,
          account.id,
          upcoming_data
        ).deliver_later
      end
    end
  end

  private def collect_birthdays(account)
    dates = (@start_date ... @end_date).map { |d| d.strftime('%m%d') }
    dates << '0229' if dates.include?('0228')
    
    Dwh::DimUser
      .where(account_id: account.id)
      .where.not(birth_date: nil)
      .where("to_char(birth_date, 'MMDD') in (?)", dates)
      .order(Arel.sql("to_char(birth_date, 'MMDD')"))
      .map { |dim_user| "#{dim_user.birth_date.strftime('%d-%m')}: #{dim_user.full_name}" }
  end

  private def collect_jubilees(account)
    dates = (@start_date ... @end_date).map { |d| d.strftime('%m%d') }
    dates << '0229' if dates.include?('0228')

    jubilee_dates = [
      { years: 25, weeks: 5 },
      { years: 20, weeks: 5 },
      { years: 15, weeks: 5 },
      { years: 10, weeks: 5 },
      { years: 5, weeks: 5 }
    ]

    # Use LPAD to ensure proper formatting of month and day
    users = Dwh::DimUser
      .where(account_id: account.id)
      .where.not(start_date: nil)
      .where(
        "LPAD(CAST(date_part('month', start_date) AS text), 2, '0') || " \
        "LPAD(CAST(date_part('day', start_date) AS text), 2, '0') IN (?)",
        dates
      )
      .order(Arel.sql("date_part('month', start_date), date_part('day', start_date)"))

    jubilee_users = []

    users.each do |user|
      next unless user.start_date.present?

      jubilee_dates.each do |jubilee|
        anniversary_date = jubilee[:years].years.ago.to_date + jubilee[:weeks].weeks
        if user.start_date.to_date == anniversary_date
          jubilee_users << "#{user.start_date.strftime('%d-%m')}: #{user.full_name} (#{jubilee[:years]} jaar)"
        end
      end
    end

    jubilee_users
  end
end
