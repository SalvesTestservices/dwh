class AuthorizationChecker
  PERMISSIONS = {
    users: [:read, :write, :delete],
    roles: [:read, :write, :delete],
    datalab: [:read, :write, :delete]
    # Add more resources and their actions as needed
  }.freeze

  def self.can?(user, action, resource)
    new(user).can?(action, resource)
  end

  def initialize(user)
    @user = user
  end

  def can?(action, resource)
    return false unless @user
    
    # Convert create/update to write for backwards compatibility
    action = :write if [:create, :update].include?(action.to_sym)
    
    @user.roles.any? do |role|
      role.permissions.include?("#{resource}:#{action}")
    end
  end

  def available_permissions
    PERMISSIONS.flat_map do |resource, actions|
      actions.map { |action| "#{resource}:#{action}" }
    end
  end
end 