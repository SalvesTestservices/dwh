require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dwh
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = "Amsterdam"
    config.encoding = "utf-8"
    
    config.i18n.available_locales = [:en, :nl]
    config.i18n.default_locale = :nl
    config.i18n.fallbacks = true

    # Configure neighbor for vector search
    config.neighbor = {
      # Configure HNSW index parameters
      index: {
        m: 16,          # Number of connections per layer
        ef_construction: 200,  # Size of dynamic candidate list for construction
        ef: 50,         # Size of dynamic candidate list for search
      },
      # Configure distance metrics
      distance: :cosine  # Use cosine similarity for embeddings
    }
  end
end
