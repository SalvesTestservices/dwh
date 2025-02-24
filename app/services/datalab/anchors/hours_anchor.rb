module Datalab
  module Anchors
    class HoursAnchor < BaseAnchor
      class << self
        def available_attributes
          {
            account_id: {
              name: 'Label',
              calculation_type: 'relation',
              description: 'Het label waar het project toe behoort',
              related_model: Dwh::DimAccount,
              display_attribute: :name
            },
            company_id: {
              name: 'Unit',
              calculation_type: 'relation',
              description: 'De unit waar het project toe behoort',
              related_model: Dwh::DimCompany,
              display_attribute: :name
            },
            user_id: {
              name: 'Naam medewerker',
              calculation_type: 'relation',
              description: 'Volledige naam van de medewerker',
              related_model: Dwh::DimUser,
              display_attribute: :full_name
            },
            month: {
              name: 'Maand',
              calculation_type: 'calculation',
              description: 'De maand waar de uren toe behoren',
              calculation: ->(record) { Calculators::HourCalculator.calculate_month(record) }
            },
            year: {
              name: 'Jaar',
              calculation_type: 'calculation',
              description: 'Het jaar waar de uren toe behoren',
              calculation: ->(record) { Calculators::HourCalculator.calculate_year(record) }
            },
            hours_parental_leave: {
              name: 'Uren ouderschapsverlof',
              calculation_type: 'calculation',
              description: 'Het aantal uren ouderschapsverlof',
              calculation: ->(record) { Calculators::HourCalculator.calculate_hours_parental_leave(record) }
            }
          }
        end

        def fetch_data(filters, page=1, items_per_page=20)
          query = base_query
          query = apply_filters(query, filters)
          query = apply_sorting(query)
          
          if page && items_per_page
            offset = (page - 1) * items_per_page
            records = query.limit(items_per_page).offset(offset)
          else
            records = query
          end
          
          total_count = query.count

          [records, total_count]
        end

        def filterable_attributes
          [:account_id, :company_id, :user_id, :month, :year]
        end

        private

        def base_query
          Dwh::FactActivity
            .joins('LEFT JOIN dim_dates ON dim_dates.id = fact_activities.activity_date')
        end

        def apply_filters(query, filters)
          return query if filters.blank?

          filters.to_unsafe_h.each do |field, value|
            next if value.blank?
            value = value.reject(&:blank?) if value.is_a?(Array)
            next if value.blank?
            
            query = case field.to_sym
            when :account_id
              query.where(account_id: value)
            when :company_id
              query.where(company_id: value)
            when :user_id
              query.where(user_id: value)
            when :month
              query.where(month: value)
            when :year
              query.where(year: value)
            else
              query
            end
          end

          query
        end

        def apply_sorting(query)
          query.joins('LEFT JOIN dim_accounts ON dim_accounts.id = fact_activities.account_id')
               .joins('LEFT JOIN dim_companies ON dim_companies.id = fact_activities.company_id')
               .joins('LEFT JOIN dim_users ON dim_users.id = fact_activities.user_id')
               .order('dim_dates.year DESC, dim_dates.month DESC, dim_accounts.name, dim_companies.name, dim_users.full_name')
        end
      end
    end
  end
end