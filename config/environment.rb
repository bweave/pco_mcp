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

# Load app files in specific order
app_root = File.expand_path("..", __dir__)

# Load ApplicationController first
require "#{app_root}/app/controllers/application_controller"
# Load other ruby files
Dir["#{app_root}/app/**/*.rb"].each do |f|
  require f unless f.end_with?("application_controller.rb")
end

# Include helpers in ApplicationController after all files are loaded
ApplicationController.helpers OauthHelpers, PlanningCenterHelpers
