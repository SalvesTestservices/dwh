module Datalab
  module Anchors
    class UsersAnchor < BaseAnchor
      class << self
        def available_attributes
          {
            full_name: {
              name: 'Naam',
              calculation_type: 'direct',
              description: 'Volledige naam van de medewerker'
            }
          }
        end

=begin
             role: {
              name: 'Rol',
              calculation_type: 'translation',
              description: 'Rol van de medewerker, bv manager, medewerker, etc.'
            },
            billable_hours: {
              name: 'Billable uren',
              calculation_type: 'complex',
              description: 'Totaal aantal billable uren van de medewerker'
            }
 

=end



        def calculate_role(user)
          case user.role
          when "employee"
            I18n.t('users.roles.employee')
          when "trainee"
            I18n.t('users.roles.trainee')
          when "subco"
            I18n.t('users.roles.subco')
          else
            user.role
          end
        end

        def calculate_turnover(user)
          # Example complex calculation
          billable_hours = user.activities.billable.sum(:hours)
          rate = user.current_rate || 0
          billable_hours * rate
        end

        def fetch_data(column_ids)
          query = Dwh::DimUser.order(:full_name)

          # Add necessary includes based on required columns
          query = query.includes(:activities) if column_ids.include?('turnover')
          
          # Add any other necessary includes
          query = query.includes(:company) if column_ids.include?('company_name')

          query
        end

        def filterable_attributes
          [:role]
        end

        def sortable_attributes
          [:first_name, :role, :turnover]
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