class Datalab::Anchors::UsersAnchor < BaseAnchor
  class << self
    def available_attributes
      {
        first_name: {
          name: 'First Name',
          calculation_type: 'direct',
          description: 'User first name'
        },
        role: {
          name: 'Role',
          calculation_type: 'translation',
          description: 'User role in the organization'
        },
        turnover: {
          name: 'Turnover',
          calculation_type: 'complex',
          description: 'Total turnover for the user'
        }
      }
    end

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

    def fetch_data(column_config)
      User.includes(:activities) # Will expand in next step
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
        # Complex sorting example
        records.left_joins(:activities)
              .group('users.id')
              .order("SUM(activities.hours * activities.rate) #{direction}")
      else
        records
      end
    end
  end
end