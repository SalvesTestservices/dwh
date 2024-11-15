source "https://rubygems.org"

gem "rails", "~> 8.0.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "mission_control-jobs"
gem "kamal", require: false
gem "thruster", require: false
gem "devise"
gem "devise_invitable"

gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jbuilder"
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "rails_live_reload"
end