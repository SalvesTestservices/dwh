class Datalab::Anchors::UsersAnchor < BaseAnchor
  class << self
    def available_attributes
      {
        first_name: {
          name: 'First Name',
          calculation_type: 'direct',
          description: 'User first name'
        },
        turnover: {
          name: 'Turnover',
          calculation_type: 'complex',
          description: 'Total turnover for the user'
        }
        # Add more attributes as needed
      }
    end

    def fetch_data(column_config)
      # Will implement in later step
      []
    end
  end
end