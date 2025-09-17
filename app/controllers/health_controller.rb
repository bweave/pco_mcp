# NOTE: just a dummy check controller to make sure things are running
class HealthController < ApplicationController
  get "/" do
    "MCP Server is running"
  end

  get "/health" do
    content_type :json
    { status: "ok", timestamp: Time.now.iso8601 }.to_json
  end
end

