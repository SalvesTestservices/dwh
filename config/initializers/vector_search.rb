# Only enable vector extension if database exists
begin
  if ActiveRecord::Base.connection.active?
    ActiveRecord::Base.connection.enable_extension('vector') unless ActiveRecord::Base.connection.extension_enabled?('vector')
  end
rescue
  # Database doesn't exist yet, skip enabling extension
end 