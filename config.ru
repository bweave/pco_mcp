require_relative "config/environment"

# Use Rack::URLMap to mount controllers at different paths
map "/" do
  use HealthController
  use DiscoveryController
  use McpController
  run lambda { |env| [ 404, {}, [ "FALLBACK: Not Found" ] ] }
end

map "/oauth" do
  run OauthController
end
