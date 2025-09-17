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

# First load helpers
Dir["#{app_root}/app/helpers/*.rb"].each { |f| require f }
# Then load models
Dir["#{app_root}/app/models/*.rb"].each { |f| require f }
# Load ApplicationController first
require "#{app_root}/app/controllers/application_controller"
# Then load other controllers
Dir["#{app_root}/app/controllers/*.rb"].each { |f|
  require f unless f.end_with?("application_controller.rb")
}

# Include helpers in ApplicationController after all files are loaded
ApplicationController.helpers OauthHelpers, PlanningCenterHelpers
