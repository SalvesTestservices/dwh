module Datalab
  module Anchors
    class ProjectsAnchor < BaseAnchor
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
            customer_id: {
              name: 'Klant',
              calculation_type: 'relation',
              description: 'De klant waar het project toe behoort',
              related_model: Dwh::DimCustomer,
              display_attribute: :name
            },
            name: {
              name: 'Project naam',
              calculation_type: 'direct',
              description: 'De naam van het project'
            },
            calculation_type: {
              name: 'Type project',
              calculation_type: 'translation',
              description: 'Het type/afrekenmethode van het project',
              method: :calculation_type,
              translation_scope: 'datalab.project.calculation_types'
            },
            start_date: {
              name: 'Startdatum',
              calculation_type: 'calculation',
              description: 'De startdatum van het project',
              calculation: ->(record) { Calculators::ProjectCalculator.calculate_start_date(record) }
            },
            end_date: {
              name: 'Einddatum',
              calculation_type: 'calculation',
              description: 'De einddatum van het project',
              calculation: ->(record) { Calculators::ProjectCalculator.calculate_end_date(record) }
            },
            expected_end_date: {
              name: 'Verwachte einddatum',
              calculation_type: 'calculation',
              description: 'De verwachte einddatum van het project',
              calculation: ->(record) { Calculators::ProjectCalculator.calculate_expected_end_date(record) }
            },
          }
        end

        def fetch_data(limit, column_ids)
          Dwh::DimProject.joins('LEFT JOIN dim_dates ON dim_dates.id = dim_projects.start_date').limit(limit)
        end

        def filterable_attributes
          [:account_id, :company_id, :customer_id, :calculation_type]
        end

        def apply_filter(records, field, value)
          case field.to_sym
          when :account_id
            records.where(account_id: value)
          when :company_id
            records.where(company_id: value)
          when :customer_id
            records.where(customer_id: value)
          when :calculation_type
            records.where(calculation_type: value)
          else
            records
          end
        end

        def apply_sorting(records)
          records.joins('LEFT JOIN dim_accounts ON dim_accounts.id = dim_projects.account_id')
                .joins('LEFT JOIN dim_companies ON dim_companies.id = dim_projects.company_id')
                .order('dim_accounts.name', 'dim_companies.name', 'dim_projects.name')
        end
      end
    end
  end
end