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
            full_name: {
              name: 'Naam',
              calculation_type: 'relation',
              description: 'Volledige naam van de medewerker',
              related_model: Dwh::DimUser,
              display_attribute: :full_name
            },
            month: {
              name: 'Maand',
              calculation_type: 'translation',
              description: 'De maand waar de uren toe behoren'
            },
            year: {
              name: 'Jaar',
              calculation_type: 'direct',
              description: 'Het jaar waar de uren toe behoren'
            },
            hours_gvp: {
              name: 'GVP uren',
              calculation_type: 'calculation',
              description: 'Het aantal uren geboorteverlof partner',
              calculation: ->(record) { Calculators::HourCalculator.calculate_hours_gvp(record) }
            },
            hours_agvp: {
              name: 'AGVP uren',
              calculation_type: 'calculation',
              description: 'Het aantal uren aanvullend geboorteverlof partner',
              calculation: ->(record) { Calculators::HourCalculator.calculate_hours_agvp(record) }
            },
            hours_ovb: {
              name: 'OVB uren',
              calculation_type: 'calculation',
              description: 'Het aantal uren ouderschapsverlof betaald',
              calculation: ->(record) { Calculators::HourCalculator.calculate_hours_ovb(record) }
            },
            hours_ovo: {
              name: 'OVO uren',
              calculation_type: 'calculation',
              description: 'Het aantal uren ouderschapsverlof onbetaald',
              calculation: ->(record) { Calculators::HourCalculator.calculate_hours_ovo(record) }
            },
            hours_apv: {
              name: 'APV uren',
              calculation_type: 'calculation',
              description: 'Het aantal uren adoptieverlof/pleegzorgverlof',
              calculation: ->(record) { Calculators::HourCalculator.calculate_hours_apv(record) }
            }
          }
        end

        def fetch_data(limit, column_ids)
          Dwh::FactActivity.joins('LEFT JOIN dim_dates ON dim_dates.id = fact_activities.activity_date').limit(limit)
        end

        def filterable_attributes
          [:account_id, :company_id, :user_id, :month, :year]
        end

        def apply_filter(records, field, value)
          case field.to_sym
          when :account_id
            records.where(account_id: value)
          when :company_id
            records.where(company_id: value)
          when :user_id
            records.where(user_id: value)
          when :month
            records.where(month: value)
          when :year
            records.where(year: value)
          else
            records
          end
        end

        def apply_sorting(records)
          records.joins('LEFT JOIN dim_accounts ON dim_accounts.id = fact_activities.account_id')
                .joins('LEFT JOIN dim_companies ON dim_companies.id = fact_activities.company_id')
                .joins('LEFT JOIN dim_users ON dim_users.id = fact_activities.user_id')
                .order('dim_accounts.name', 'dim_companies.name', 'dim_users.full_name')
        end
      end
    end
  end
end