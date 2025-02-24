module Datalab
  module Anchors
    class UsersAnchor < BaseAnchor
      class << self
        def available_attributes
          {
            account_id: {
              name: 'Label',
              calculation_type: 'relation',
              description: 'Het label waar de medewerker werkzaam is',
              related_model: Dwh::DimAccount,
              display_attribute: :name
            },
            company_id: {
              name: 'Unit',
              calculation_type: 'relation',
              description: 'De unit waar de medewerker werkzaam is',
              related_model: Dwh::DimCompany,
              display_attribute: :name
            },
            full_name: {
              name: 'Naam',
              calculation_type: 'direct',
              description: 'Volledige naam van de medewerker'
            },
            email: {
              name: 'Email',
              calculation_type: 'direct',
              description: 'Email van de medewerker'
            },
            contract: {
              name: 'Contract type',
              calculation_type: 'direct',
              description: 'Contract type van de medewerker'
            },
            contract_hours: {
              name: 'Contract uren',
              calculation_type: 'direct',
              description: 'Contract uren van de medewerker'
            },
            salary: {
              name: 'Salaris',
              calculation_type: 'direct',
              description: 'Salaris van de medewerker o.b.v. fulltime contract'
            },
            address: {
              name: 'Adres',
              calculation_type: 'direct',
              description: 'Adres van de medewerker'
            },
            city: {
              name: 'Woonplaats',
              calculation_type: 'direct',
              description: 'Woonplaats van de medewerker'
            },
            country: {
              name: 'Land',
              calculation_type: 'direct',
              description: 'Land van de medewerker'
            },
            role: {
              name: 'Rol',
              calculation_type: 'direct',
              description: 'Rol van de medewerker, bv manager, medewerker, etc.'
            },
            start_date: {
              name: 'Datum in dienst',
              calculation_type: 'calculation',
              description: 'Datum waarop de medewerker in dienst is gekomen',
              calculation: ->(record) { Calculators::UserCalculator.calculate_start_date(record) }
            },
            leave_date: {
              name: 'Datum uit dienst',
              calculation_type: 'calculation',
              description: 'Datum waarop de medewerker uit dienst is gegaan',
              calculation: ->(record) { Calculators::UserCalculator.calculate_leave_date(record) }
            },
            cost_price: {
              name: 'Kostprijs',
              calculation_type: 'calculation',
              description: 'Kostprijs van de medewerker in de meest recente maand',
              calculation: ->(record) { Calculators::UserCalculator.calculate_cost_price(record) }
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
          [:account_id, :company_id, :contract, :role]
        end

        private

        def base_query
          Dwh::DimUser
            .joins('LEFT JOIN dim_dates ON dim_dates.id = dim_users.leave_date')
            .where('leave_date IS NULL OR dim_dates.original_date > ?', Date.current)
            .order('dim_accounts.name', 'dim_companies.name', 'dim_users.full_name')
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
            when :contract
              query.where(contract: value)
            when :role
              query.where(role: value)
            else
              query
            end
          end

          query
        end

        def apply_sorting(query)
          query.joins('LEFT JOIN dim_accounts ON dim_accounts.id = dim_users.account_id')
               .joins('LEFT JOIN dim_companies ON dim_companies.id = dim_users.company_id')
               .order('dim_accounts.name', 'dim_companies.name', 'dim_users.full_name')
        end
      end
    end
  end
end