class AuthorizationChecker
  PERMISSIONS = {
    datalab: [:read, :write, :delete],
    data_pipelines: [:read, :write, :delete],
    data_targets: [:read, :write, :delete],
    data_reports: [:read, :write, :delete],
    data_governance: [:read, :write, :delete],
    data_api: [:read, :write, :delete],
    users: [:read, :write, :delete],
    employees: [:read],
    roles: [:read, :write, :delete],
    employee_overviews: [:read, :write, :delete],
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