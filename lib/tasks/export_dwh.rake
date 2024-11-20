module ExportHelper
  def self.contract_type(contract)
    case contract
    when "fixed"
      I18n.t('.users.contracts.fixed')
    when "ibo"
      I18n.t('.users.contracts.ibo')
    when "midlance"
      I18n.t('.users.contracts.midlance')
    when "temporary"
      I18n.t('.users.contracts.temporary')
    else
      I18n.t('.users.contracts.temporary')
    end
  end

  def self.role_field(account, role)
    user_role = account.roles.find_by(technical_name: role)
    if user_role.blank?
      I18n.t(".users.roles.#{role}")
    else
      user_role.name
    end
  end
end

task export_users: :environment do
  csv = CSV.open('users.csv', 'w+', col_sep: ',')
  csv << ['Label','Unit/BV','Medewerker','Datum in dienst','Datum uit dienst',
    'Rol 2022','Contract 2022','Contract uren 2022','FTE 2022','Bruto salaris 2022','Maandelijkse vaste bonus 2022', 'Variabele bonus 2022','Declarabele uren 2022','Extra bonusdragende uren 2022', 'Gem tarief 2022','Omzet 2022',
    'Rol 2023','Contract 2023','Contract uren 2023','FTE 2023','Bruto salaris 2023','Maandelijkse vaste bonus 2023', 'Variabele bonus 2023','Declarabele uren 2023','Extra bonusdragende uren 2023', 'Gem tarief 2023', 'Omzet 2023',
    'Rol 2024','Contract 2024','Contract uren 2024','FTE 2024','Bruto salaris 2024','Maandelijkse vaste bonus 2024', 'Variabele bonus 2024','Declarabele uren 2024','Extra bonusdragende uren 2024', 'Gem tarief 2024', 'Omzet 2024'
  ]

  account = Account.find(2)
  companies = account.companies.active.where.not(id:2).order(:name)
  companies.each do |company|
    users = company.users.includes(:company).where("role != 'external' AND role != 'rws_level1' AND role != 'rws_level2' AND role != 'api' AND role != 'viewer' AND role != 'powerbi'").order(:first_name)
    users = users.where("leave_date IS NULL OR leave_date >= ?", Date.new(2022,10,1))
    users.each do |user|
      puts "USER #{user.id} - #{user.full_name}"
      leave_date = user.leave_date.present? ? user.leave_date.strftime("%d-%m-%Y") : ""
      user_contract_hours = user.user_contract_hours

      # 2022
      if user.start_date <= Date.new(2022,12,31) && (user.leave_date.present? ? user.leave_date > Date.new(2022,1,1) : true)
        user_contract_hour = user_contract_hours.where("start_date <= ? AND role IS NOT NULL AND role != ''", Date.new(2022,10,1)).order(start_date: :desc).first
        role_2022 = ExportHelper.role_field(account, user_contract_hour&.role || user.role)

        user_contract_hour = user_contract_hours.where("start_date <= ? AND contract_type IS NOT NULL AND contract_type != ''", Date.new(2022,10,1)).order(start_date: :desc).first
        contract_2022 = ExportHelper.contract_type(user_contract_hour&.contract_type || user.contract)

        user_contract_hour = user_contract_hours.where("start_date <= ? AND contract_hours IS NOT NULL AND contract_hours != 0", Date.new(2022,10,1)).order(start_date: :desc).first
        contract_hours_2022 = user_contract_hour&.contract_hours || user.contract_hours
        fte_2022 = contract_hours_2022 / 40

        user_contract_hour = user_contract_hours.where("start_date <= ? AND salary_mutation IS NOT NULL AND salary_mutation != 0", Date.new(2022,10,1)).order(start_date: :desc).first
        salary_2022 = user_contract_hour&.salary_mutation

        user_contract_hour = user_contract_hours.where("start_date <= ? AND fixed_bonus IS NOT NULL AND fixed_bonus != 0", Date.new(2022,10,1)).order(start_date: :desc).first
        monthly_bonus_2022 = user_contract_hour&.fixed_bonus

        projectusers = user.projectusers.by_year(2022).includes(project: :customer).includes(:phourtypes)

        variable_bonus_2022 = 0
        iterated_bonuses = BonusIterator.new(user, 2022).create_bonus_iterations(projectusers)
        iterated_bonuses.each do |bonus_type, month, show_month, show_project, customer_name, bonus_name, hour_code, project_hours, bonus_factor, total_hours, bonus_amount, bonus_explanation|
          if bonus_type == "bonus_rule"
            variable_bonus_2022 += bonus_amount
          end
        end

        extra_bonus_hours_2022 = 0
        timesheets = user.timesheets.where("year = 2022")
        unless timesheets.blank?
          timesheets.each do |timesheet|
            activities = timesheet.activities
            unless activities.blank?
              extra_bonus_hours_2022 += activities.where("unbillable_id = 5 OR unbillable_id = 6").sum(:hours)
            end
          end
        end

        calculator = EmployeeCalculator.new(user)
        declarable_hours_2022 = 0
        turnover_2022 = 0
        average_rate_2022 = 0

        projectusers.each do |projectuser|
          phourtypes = projectuser.phourtypes.includes(:pupdates)
          phourtypes.each do |phourtype|
            hours = calculator.get_phourtype_data("hours", phourtype.id, 2022)
            rate = calculator.get_project_data(projectuser, "rate", phourtype)
            declarable_hours_2022 += hours
            turnover_2022 += hours * rate
          end
        end

        turnover_2022 = turnover_2022.round(2) unless turnover_2022.blank?

        if turnover_2022 == 0 || declarable_hours_2022 == 0
          average_rate_2022 = 0
        else
          average_rate_2022 = (turnover_2022 / declarable_hours_2022).round(2)
        end
      end

      # 2023
      if user.start_date <= Date.new(2023,12,31) && (user.leave_date.present? ? user.leave_date > Date.new(2023,1,1) : true)
        user_contract_hour = user_contract_hours.where("start_date <= ? AND role IS NOT NULL AND role != ''", Date.new(2023,10,1)).order(start_date: :desc).first
        role_2023 = ExportHelper.role_field(account, user_contract_hour&.role || user.role)

        user_contract_hour = user_contract_hours.where("start_date <= ? AND contract_type IS NOT NULL AND contract_type != ''", Date.new(2023,10,1)).order(start_date: :desc).first
        contract_2023 = ExportHelper.contract_type(user_contract_hour&.contract_type || user.contract)

        user_contract_hour = user_contract_hours.where("start_date <= ? AND contract_hours IS NOT NULL AND contract_hours != 0", Date.new(2023,10,1)).order(start_date: :desc).first
        contract_hours_2023 = user_contract_hour&.contract_hours || user.contract_hours
        fte_2023 = contract_hours_2023 / 40

        user_contract_hour = user_contract_hours.where("start_date <= ? AND salary_mutation IS NOT NULL AND salary_mutation != 0", Date.new(2023,10,1)).order(start_date: :desc).first
        salary_2023 = user_contract_hour&.salary_mutation

        user_contract_hour = user_contract_hours.where("start_date <= ? AND fixed_bonus IS NOT NULL AND fixed_bonus != 0", Date.new(2023,10,1)).order(start_date: :desc).first
        monthly_bonus_2023 = user_contract_hour&.fixed_bonus

        projectusers = user.projectusers.by_year(2023).includes(project: :customer).includes(:phourtypes)

        variable_bonus_2023 = 0
        iterated_bonuses = BonusIterator.new(user, 2023).create_bonus_iterations(projectusers)
        iterated_bonuses.each do |bonus_type, month, show_month, show_project, customer_name, bonus_name, hour_code, project_hours, bonus_factor, total_hours, bonus_amount, bonus_explanation|
          if bonus_type == "bonus_rule"
            variable_bonus_2023 += bonus_amount
          end
        end

        extra_bonus_hours_2023 = 0
        timesheets = user.timesheets.where("year = 2023")
        unless timesheets.blank?
          timesheets.each do |timesheet|
            activities = timesheet.activities
            unless activities.blank?
              extra_bonus_hours_2023 += activities.where("unbillable_id = 5 OR unbillable_id = 6").sum(:hours)
            end
          end
        end

        calculator = EmployeeCalculator.new(user)
        declarable_hours_2023 = 0
        turnover_2023 = 0
        average_rate_2023 = 0

        projectusers.each do |projectuser|
          phourtypes = projectuser.phourtypes.includes(:pupdates)
          phourtypes.each do |phourtype|
            hours = calculator.get_phourtype_data("hours", phourtype.id, 2023)
            rate = calculator.get_project_data(projectuser, "rate", phourtype)
            declarable_hours_2023 += hours
            turnover_2023 += hours * rate
          end
        end

        turnover_2023 = turnover_2023.round(2) unless turnover_2023.blank?

        if turnover_2023 == 0 || declarable_hours_2023 == 0
          average_rate_2023 = 0
        else
          average_rate_2023 = (turnover_2023 / declarable_hours_2023).round(2)
        end
      end

      # 2024
      if user.start_date <= Date.new(2024,12,31) && (user.leave_date.present? ? user.leave_date > Date.new(2024,1,1) : true)
        user_contract_hour = user_contract_hours.where("start_date <= ? AND role IS NOT NULL AND role != ''", Date.new(2024,10,1)).order(start_date: :desc).first
        role_2024 = ExportHelper.role_field(account, user_contract_hour&.role || user.role)

        user_contract_hour = user_contract_hours.where("start_date <= ? AND contract_type IS NOT NULL AND contract_type != ''", Date.new(2024,10,1)).order(start_date: :desc).first
        contract_2024 = ExportHelper.contract_type(user_contract_hour&.contract_type || user.contract)

        user_contract_hour = user_contract_hours.where("start_date <= ? AND contract_hours IS NOT NULL AND contract_hours != 0", Date.new(2024,10,1)).order(start_date: :desc).first
        contract_hours_2024 = user_contract_hour&.contract_hours || user.contract_hours
        fte_2024 = contract_hours_2024 / 40

        user_contract_hour = user_contract_hours.where("start_date <= ? AND salary_mutation IS NOT NULL AND salary_mutation != 0", Date.new(2024,10,1)).order(start_date: :desc).first
        salary_2024 = user_contract_hour&.salary_mutation

        user_contract_hour = user_contract_hours.where("start_date <= ? AND fixed_bonus IS NOT NULL AND fixed_bonus != 0", Date.new(2024,10,1)).order(start_date: :desc).first
        monthly_bonus_2024 = user_contract_hour&.fixed_bonus

        projectusers = user.projectusers.by_year(2024).includes(project: :customer).includes(:phourtypes)

        variable_bonus_2024 = 0
        iterated_bonuses = BonusIterator.new(user, 2024).create_bonus_iterations(projectusers)
        iterated_bonuses.each do |bonus_type, month, show_month, show_project, customer_name, bonus_name, hour_code, project_hours, bonus_factor, total_hours, bonus_amount, bonus_explanation|
          if bonus_type == "bonus_rule"
            variable_bonus_2024 += bonus_amount
          end
        end

        extra_bonus_hours_2024 = 0
        timesheets = user.timesheets.where("year = 2024")
        unless timesheets.blank?
          timesheets.each do |timesheet|
            activities = timesheet.activities
            unless activities.blank?
              extra_bonus_hours_2024 += activities.where("unbillable_id = 5 OR unbillable_id = 6").sum(:hours)
            end
          end
        end

        calculator = EmployeeCalculator.new(user)
        declarable_hours_2024 = 0
        turnover_2024 = 0
        average_rate_2024 = 0

        projectusers.each do |projectuser|
          phourtypes = projectuser.phourtypes.includes(:pupdates)
          phourtypes.each do |phourtype|
            hours = calculator.get_phourtype_data("hours", phourtype.id, 2024)
            rate = calculator.get_project_data(projectuser, "rate", phourtype)
            declarable_hours_2024 += hours
            turnover_2024 += hours * rate
          end
        end

        turnover_2024 = turnover_2024.round(2) unless turnover_2024.blank?

        if turnover_2024 == 0 || declarable_hours_2024 == 0
          average_rate_2024 = 0
        else
          average_rate_2024 = (turnover_2024 / declarable_hours_2024).round(2)
        end
      end

      csv << [account.name, user.company.name, user.full_name, user.start_date.strftime("%d-%m-%Y"), leave_date,
        role_2022, contract_2022, contract_hours_2022, fte_2022, salary_2022, monthly_bonus_2022, variable_bonus_2022, declarable_hours_2022, extra_bonus_hours_2022, average_rate_2022, turnover_2022,
        role_2023, contract_2023, contract_hours_2023, fte_2023, salary_2023, monthly_bonus_2023, variable_bonus_2023, declarable_hours_2023, extra_bonus_hours_2023, average_rate_2023, turnover_2023,
        role_2024, contract_2024, contract_hours_2024, fte_2024, salary_2024, monthly_bonus_2024, variable_bonus_2024, declarable_hours_2024, extra_bonus_hours_2024, average_rate_2024, turnover_2024
      ]
    end
  end
end