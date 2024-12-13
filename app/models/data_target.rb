class DataTarget < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  
  validates :account_id, :company_id, :year, :month, :role, presence: true

  after_save :update_remaining_quarters

  def workable_hours
    DwCalculator.new.workable_hours_in_month(year, month)
  end

  def productivity(show_percentage = true)
    productivity = ((billable_hours.to_f / workable_hours.to_f)*100).round(2)
    productivity = "#{productivity}%" if show_percentage == true
    productivity
  end

  def hour_rate(show_euro_sign = true)
    hour_rate = (cost_price.to_f / (100 - bruto_margin))*100
    hour_rate = number_to_currency(hour_rate, precision: 2, separator: ',') if show_euro_sign == true
    hour_rate
  end

  def fte_delta
    current_month_date = Date.new(year, month, 1)
    prev_month_date = current_month_date.prev_month
    previous_company_target = CompanyTarget.find_by(company_id: company_id, role: role, year: prev_month_date.year, month: prev_month_date.month)

    if previous_company_target.blank?
      fte_delta = 0.0
    else
      fte_delta = fte - previous_company_target.fte
    end
    fte_delta
  end

  def turnover(show_euro_sign = true)
    turnover = fte * hour_rate(false).to_f * billable_hours
    turnover = number_to_currency(turnover, precision: 2, separator: ',') if show_euro_sign == true
    turnover
  end

  private def update_remaining_quarters
    remaining_quarters = (self.quarter + 1).upto(4).to_a
    unless remaining_quarters.blank?
      remaining_quarters.each do |rq|
        company_target = CompanyTarget.find_by(company_id: self.company_id, year: self.year, month: self.month, quarter: rq, role: self.role)
        unless company_target.blank?
          company_target.update(fte: self.fte) unless company_target.fte > 0
          company_target.update(billable_hours: self.billable_hours) unless company_target.billable_hours > 0
          company_target.update(cost_price: self.cost_price) unless company_target.cost_price > 0
          company_target.update(bruto_margin: self.bruto_margin) unless company_target.bruto_margin > 0
        end
      end
    end
  end
end