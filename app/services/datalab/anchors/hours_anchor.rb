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
            }
          }
        end

        def fetch_data(filters, page=1, items_per_page=20)
          offset = (page - 1) * items_per_page
          
          query = base_query
          query = apply_filters(query, filters)
          query = apply_sorting(query)
          
          records = query.limit(items_per_page).offset(offset)
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

          filters.to_unsafe_h.each do |field, values|
            next if values.blank?
            values = values.flatten.reject(&:blank?)
            next if values.empty?
            
            query = case field.to_sym
            when :account_id
              query.where(account_id: values)
            when :company_id
              query.where(company_id: values)
            when :user_id
              query.where(user_id: values)
            when :month
              query.where(month: values)
            when :year
              query.where(year: values)
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