class DwCalculator

  def initialize
  end

  def avg_rate(user, month, year)
    avg_rate = nil

    active_projectusers = user.active_projects(year, month)
    unless active_projectusers.blank?
      if active_projectusers.count == 1
        check_date = Date.new(year, month, 1)
        rate_calculator = RateCalculator.new(nil, active_projectusers.first, nil)
        rate = rate_calculator.calculate_rate("rate", check_date)
        internal_rate = rate_calculator.calculate_rate("internal_rate", check_date)

        if internal_rate.present? and internal_rate > 0
          avg_rate = internal_rate
        else
          avg_rate = rate
        end
      else
        avg_rate = calculate_avg_rate(user, active_projectusers, month, year)
      end
    end

    avg_rate.round(2) unless avg_rate.blank?
    avg_rate
  end

  def hours(user, month, year)
    user.timesheets
      .where(status: "approved", month: month, year: year)
      .joins(:activities)
      .where("projectuser_id IS NOT NULL AND unbillable_id IS NULL")
      .sum(:hours)
      .round(2)
  end

  def bcr(user, month, year)
    return calculate_bcr_for_external_user(user, month, year) if user.external?
  
    company = user.company
    company_avg_salary = company_avg_salary(company.users, month, year)
    company_bcr = company_bcr(company, year)
    bcr = company_bcr.blank? ? nil : (company_bcr/company_avg_salary)*user_salary(user, month, year).to_f.round(2)
    bcr = nil if bcr.present? and bcr == 0.0

    bcr
  end
  
  def ucr(user, month, year)
    company = user.company
    company_avg_salary = company_avg_salary(company.users, month, year)
    company_ucr = company_ucr(company, year)

    ucr = company_ucr.blank? ? nil : (company_ucr/company_avg_salary)*user_salary(user, month, year).to_f.round(2)
    ucr = nil if ucr.present? and ucr == 0.0

    ucr
  end

  def company_bcr(company, year)
    year_figure = company.year_figures.find_by(year: year)
    company_bcr = year_figure&.bcr || nil
    company_bcr.round(2) unless company_bcr.blank?
  end

  def company_ucr(company, year)
    year_figure = company.year_figures.find_by(year: year)
    company_ucr = year_figure&.ucr || nil
    company_ucr.round(2) unless company_ucr.blank?
  end

  def contract(user, month, year)
    user_contract_hours = user.user_contract_hours.where("start_date <= ? AND contract_type IS NOT NULL", Date.new(year, month, 1)).order(:start_date)
    contract = user_contract_hours.blank? ? user.contract : user_contract_hours.last.contract_type
    contract = "fixed" if contract == "ibo"
    contract
  end

  def contract_hours(user, month, year)
    user_contract_hours = user.user_contract_hours.where("start_date <= ? AND contract_hours IS NOT NULL", Date.new(year, month, 1)).order(:start_date)
    user_contract_hours.blank? ? user.contract_hours : user_contract_hours.last.contract_hours
  end

  def role(user, month, year)
    user_contract_hours = user.user_contract_hours.where("start_date <= ? AND role IS NOT NULL", Date.new(year, month, 1)).order(:start_date)
    if user_contract_hours.blank? or user_contract_hours.last.role.blank?
      user.role
    else
      user_contract_hours.last.role
    end
  end

  def user_salary(user, month, year)
    if user.contract == "midlance"
      salary = user.account.midlancer_salary.blank? ? 0 : user.account.midlancer_salary
    else
      user_contract_hours = user.user_contract_hours.where("start_date <= ? AND salary_mutation IS NOT NULL", Date.new(year, month, 1)).order(:start_date)
      salary = user_contract_hours.blank? ? user.salary : user_contract_hours.last.salary_mutation
    end
  end

  def workable_hours_in_month(year, month)
    total_work_hours = 0.0
    start_date = Date.new(year, month, 1)
    end_date = Date.new(year, month, -1)
    
    (start_date..end_date).each do |date|
      if date.wday.between?(1, 5)
        total_work_hours += 8
      end
    end
  
    total_work_hours
  end

  def fte_previous_year(company, role, current_year)
    fte = 0.0
    current_month_date = Date.new(current_year.to_i, 1, 1)
    users = company.users.where("start_date < ? AND (leave_date IS NULL OR leave_date >= ?)", current_month_date, current_month_date)

    case role
    when "trainee"
      users = users.where(trainee: true)
    when "subco"
      users = users.where(role: "external")
    when "employee"
      users = users.where(trainee: false, role: ["employee","mc", "dm"])
    end

    unless users.blank?
      users.each do |user|
        if user.contract_hours.blank? or user.contract_hours == 0
          fte += 1
        else
          fte += user.contract_hours.to_d/40.0.to_d
        end
      end
    end
    fte
  end

  private def calculate_avg_rate(user, active_projectusers, month, year)
    avg_rate = 0
    total_turnover = 0
    total_quantities = 0

    active_projectusers.each do |projectuser|
      projectuser.phourtypes.each do |phourtype|
        quantities = calculate_project_hours(user, projectuser.id, month, year, phourtype.id)
        if quantities > 0
          rate_calculator = RateCalculator.new(nil, projectuser, phourtype)
          rate = rate_calculator.calculate_rate("rate")
          internal_rate = rate_calculator.calculate_rate("internal_rate")

          if internal_rate.present? and internal_rate > 0
            used_rate = internal_rate
          else
            used_rate = rate
          end

          total_turnover += used_rate*quantities
          total_quantities += quantities
        end
      end
    end

    if total_quantities == 0 or total_turnover == 0
      used_rate = 0
      counter = 0
      active_projectusers.each do |projectuser|
        rate_calculator = RateCalculator.new(nil, projectuser, nil)
        rate = rate_calculator.calculate_rate("rate")
        internal_rate = rate_calculator.calculate_rate("internal_rate")
        
        if internal_rate.present?
          used_rate += internal_rate
        else
          used_rate += rate
        end
        counter += 1
      end
      avg_rate = used_rate/counter
    else
      avg_rate = total_turnover/total_quantities
    end
    avg_rate
  end

  private def calculate_project_hours(user, projectuser_id, month, year, phourtype_id)
    hours = 0
    timesheets = user.timesheets.where(status: "approved", month: month, year: year)
    unless timesheets.blank?
      timesheets.each do |timesheet|
        activities = timesheet.activities.where(projectuser_id: projectuser_id, phourtype_id: phourtype_id)
        unless activities.blank?
          activities.each do |activity|
            hours += activity.hours
          end
        end
      end
    end
    hours
  end

  private def company_avg_salary(users, month, year)
    if users.blank?
      avg_salary = 0
    else
      total_salary = 0
      counter = 0
      users.each do |user|
        unless user.salary.blank?
          if user.contract == "midlance"
            midlancer_salary = user.account.midlancer_salary.blank? ? 0 : user.account.midlancer_salary
            total_salary += midlancer_salary
          else
            total_salary += user_salary(user, month, year)
          end
          counter += 1
        end
      end
      if total_salary == 0 or counter == 0
        avg_salary = 0
      else
        avg_salary = total_salary/counter
      end
    end
    avg_salary
  end

  private def calculate_bcr_for_external_user(user, month, year)
    active_projects = user.active_projects(year, month)
    return nil if active_projects.blank?
  
    last_day = Date.new(year, month, 1).end_of_month.day.to_i
    if active_projects.count == 1
      RateCalculator.new(nil, active_projects.first).calculate_rate("purchase_price", Date.new(year, month, last_day))
    else
      purchase_prices = active_projects.sum do |project|
        RateCalculator.new(nil, project).calculate_rate("purchase_price", Date.new(year, month, last_day))
      end
      (purchase_prices / active_projects.count).round(2)
    end
  end
end