class ApplicationController < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  configure do
    set :session_secret, ENV["SESSION_SECRET"] || "dev_secret_key"
    enable :sessions

    # Logs
    enable :logging
    log_dir = File.join(File.expand_path("../../..", __dir__), "log")
    FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
    log_file = File.new("#{log_dir}/#{environment}.log", "a+")
    log_file.sync = true
    use Rack::CommonLogger, log_file
  end

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path("../../..", __dir__)
  end
end