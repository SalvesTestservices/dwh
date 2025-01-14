Rails.application.config.session_store :cache_store,
  key: '_dwh_session',
  expire_after: 30.days,
  cache: Rails.cache