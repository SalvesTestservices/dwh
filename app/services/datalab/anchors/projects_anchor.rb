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
            name: {
              name: 'Project naam',
              calculation_type: 'direct',
              description: 'De naam van het project'
            }
          }
        end

        def fetch_data(limit, column_ids)
          Dwh::DimProject.joins('LEFT JOIN dim_dates ON dim_dates.id = dim_projects.start_date').limit(limit)
        end

        def filterable_attributes
          [:account_id, :company_id]
        end

        def apply_filter(records, field, value)
          case field.to_sym
          when :account_id
            records.where(account_id: value)
          when :company_id
            records.where(company_id: value)
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