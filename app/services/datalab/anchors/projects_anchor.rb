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
              name: 'Project',
              calculation_type: 'direct',
              description: 'Naam van het project'
            },
            project_number: {
              name: 'Project nummer',
              calculation_type: 'direct',
              description: 'Nummer van het project'
            },
            status: {
              name: 'Status',
              calculation_type: 'direct',
              description: 'Status van het project'
            },
            start_date: {
              name: 'Start datum',
              calculation_type: 'direct',
              description: 'Start datum van het project'
            },
            end_date: {
              name: 'Eind datum',
              calculation_type: 'direct',
              description: 'Eind datum van het project'
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
          [:account_id, :company_id, :status]
        end

        private

        def base_query
          Dwh::DimProject.all
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
            when :status
              query.where(status: value)
            else
              query
            end
          end

          query
        end

        def apply_sorting(query)
          query.joins('LEFT JOIN dim_accounts ON dim_accounts.id = dim_projects.account_id')
               .joins('LEFT JOIN dim_companies ON dim_companies.id = dim_projects.company_id')
               .order('dim_accounts.name, dim_companies.name, dim_projects.name')
        end
      end
    end
  end
end