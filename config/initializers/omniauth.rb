Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph,
    ENV['MICROSOFT_CLIENT_ID'],
    ENV['MICROSOFT_CLIENT_SECRET'],
    tenant_id: 'common',
    scope: 'openid profile email User.Read'
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true