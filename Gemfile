# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.3.2"

# Core gems
gem "sinatra", "~> 4.0"
gem "sinatra-activerecord", "~> 2.0"
gem "fast-mcp", "~> 0.1"
gem "activerecord", "~> 7.1"

# Database adapters
gem "sqlite3", "~> 1.7", group: :development
gem "mysql2", "~> 0.5", group: :production

# Server and middleware
gem "puma", "~> 6.0"
gem "rackup", "~> 2.0"
gem "rack-cors", "~> 2.0"

group :development do
  # Auto-reloading
  gem "rerun", "~> 0.14"

  # Code quality and formatting
  gem "rubocop-rails-omakase", "~> 1.0", require: false

  # Development utilities
  gem "dotenv", "~> 3.0"
end

group :development, :test do
  gem "rake", "~> 13.0"
end

group :test do
  gem "minitest", "~> 5.20"
end
