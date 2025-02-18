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
      # Skip if the account is not in the notification receivers list
      next unless notification_receivers[account.name]

      # Collect the upcoming data for the account
      upcoming_data = {
        birthdays: collect_birthdays(account),
        jubilees: collect_jubilees(account)
      }

      # Send the notifications to the receivers
      notification_receivers[account.name].each do |receiver_email|
        UserMailer.weekly_notifications(
          receiver_email,
          account.id,
          upcoming_data
        ).deliver_later
      end
    end
  end

  private def collect_birthdays(account)
    birthdays = []

    dates = (@start_date ... @end_date).map { |d| d.strftime('%d%m').sub(/^0/, '') }
    dates << '2902' if dates.include?('2802')

    dim_users = Dwh::DimUser.where(account_id: account.id).where.not(birth_date: nil).order(:birth_date)
    unless dim_users.blank?
      dim_users.each do |dim_user|
        day = dim_user.birth_date.to_s.length == 7 ? dim_user.birth_date.to_s[0..0] : dim_user.birth_date.to_s[0..1]
        month = dim_user.birth_date.to_s.length == 7 ? dim_user.birth_date.to_s[1..2] : dim_user.birth_date.to_s[2..3]
        formatted_birth_date = "#{day}#{month}"

        if dates.include?(formatted_birth_date.to_s)
          birthdays << "#{day}-#{month}: #{dim_user.full_name}"
        end
      end
    end

    birthdays
  end

  private def collect_jubilees(account)
    jubilees = []

    dates = (@start_date ... @end_date).map { |d| d.strftime('%d%m').sub(/^0/, '') }
    dates << '2902' if dates.include?('2802')

    dim_users = Dwh::DimUser.where(account_id: account.id).where.not(start_date: nil).order(:start_date)
    unless dim_users.blank?
      dim_users.each do |dim_user|
        day = dim_user.start_date.to_s.length == 7 ? dim_user.start_date.to_s[0..0] : dim_user.start_date.to_s[0..1]
        month = dim_user.start_date.to_s.length == 7 ? dim_user.start_date.to_s[1..2] : dim_user.start_date.to_s[2..3]
        year = dim_user.start_date.to_s.length == 7 ? dim_user.start_date.to_s[3..6] : dim_user.start_date.to_s[4..7]
        formatted_start_date = "#{day}#{month}"

        if dates.include?(formatted_start_date)
          # Calculate years of service
          years_of_service = Date.current.year - year.to_i

          # Check if it's a milestone anniversary (5, 10, 15, 20, or 25 years)
          if [5, 10, 15, 20, 25].include?(years_of_service)
            jubilees << "#{day}-#{month}: #{dim_user.full_name} (#{years_of_service} jaar)"
          end
        end
      end
    end

    jubilees
  end
end
