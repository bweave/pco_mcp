# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.3.2"

# Core gems
gem "sinatra", "~> 4.0"
gem "sinatra-activerecord", "~> 2.0"
gem "activerecord", "~> 7.1"
gem "mcp", "~> 0.3.0"
gem "dotenv", "~> 3.0"

# OAuth and authentication
gem "rodauth", "~> 2.0"
gem "rodauth-oauth", "~> 1.6"
gem "roda", "~> 3.0"
gem "oauth2", "~> 2.0"

# Database adapters
gem "sqlite3", "~> 1.7"

# Server and middleware
gem "puma", "~> 6.0"
gem "rackup", "~> 2.0"
gem "rack-cors", "~> 2.0"

group :development do
  # Auto-reloading
  gem "rerun", "~> 0.14"

  # Code quality and formatting
  gem "rubocop-rails-omakase", "~> 1.0", require: false
end

group :development, :test do
  gem "better_errors", "~> 2.10"
  gem "binding_of_caller", "~> 1.0"
  gem "debug"
  gem "rake", "~> 13.0"
end

group :test do
  gem "minitest", "~> 5.20"
end
