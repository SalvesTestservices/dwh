source "https://rubygems.org"

gem "rails", "~> 8.0.1"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "requestjs-rails"
gem "solid_cache"
gem "solid_cable"
gem "kamal", require: false
gem "thruster", require: false

gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jbuilder"
gem "view_component", "~> 3.21.0"
gem "acts_as_list"
gem "devise"
gem "pagy"
gem "good_job"
gem "httparty"
gem "roo"
gem "caxlsx"
gem "caxlsx_rails"
gem "omniauth-microsoft_graph"
gem "omniauth-rails_csrf_protection"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "rails_live_reload"
  gem 'foreman'
end

platforms :ruby, :mswin, :mingw, :x64_mingw do
  gem 'ffi'
end