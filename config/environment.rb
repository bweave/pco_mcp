ENV["SINATRA_ENV"] ||= "development"

require "bundler/setup"
Bundler.require(:default, ENV["SINATRA_ENV"])
if ENV["SINATRA_ENV"] == "development" || ENV["SINATRA_ENV"] == "test"
  require "better_errors"
  require "debug"
end

# Load environment variables
require "dotenv/load" if ENV["SINATRA_ENV"] == "development"

ActiveRecord::Base.establish_connection(
  ENV["SINATRA_ENV"].to_sym
)

# Load app files
Dir["#{File.expand_path("..", __dir__)}/app/**/*.rb"].each { |f| require f }

require_relative "../app"
