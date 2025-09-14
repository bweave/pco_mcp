require_relative "config/environment"

# Use Rack::URLMap to mount controllers at different paths
map "/" do
  use HealthController  # Root routes like "/" and "/health"
  run McpController     # MCP JSON-RPC POST requests to "/"
end

map "/oauth" do
  run OauthController   # All OAuth routes under /oauth/*
end

map "/api" do
  run ApiController     # All API routes under /api/*
end
