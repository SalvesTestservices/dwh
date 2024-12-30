module Datalab
  module Anchors
    class UsersAnchor < BaseAnchor
      class << self
        def available_attributes
          {
            account_id: {
              name: 'Label',
              calculation_type: 'relation_id',
              description: 'Het label waar de medewerker werkzaam is',
              related_model: Dwh::DimAccount,
              display_attribute: :name
            },
            company_id: {
              name: 'Unit',
              calculation_type: 'relation_id',
              description: 'De unit waar de medewerker werkzaam is',
              related_model: Dwh::DimCompany,
              display_attribute: :name_short
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

        def fetch_data(column_ids)
          Dwh::DimUser.order(:full_name)
        end

        def filterable_attributes
          [:role]
        end

        def sortable_attributes
          [:account_id, :company_id, :first_name, :last_name, :role, :contract, :salary, :cost_price]
        end

        def apply_filter(records, field, value)
          case field.to_sym
          when :role
            records.where(role: value)
          else
            records
          end
        end

        def apply_sorting(records, field, direction)
          case field.to_sym
          when :first_name
            records.order(first_name: direction)
          when :role
            records.order(role: direction)
          when :turnover
            # Optimize complex sorting with subquery
            records.left_joins(:activities)
                  .select('users.*, COALESCE(SUM(activities.hours * activities.rate), 0) as calculated_turnover')
                  .group('users.id')
                  .order("calculated_turnover #{direction}")
          else
            records
          end
        end
      end
    end
  end
end