class McpServer < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  configure :development do
    enable :logging
  end

  get "/" do
    "MCP Server is running"
  end

  get "/health" do
    content_type :json
    { status: 'ok', timestamp: Time.now.iso8601 }.to_json
  end
end
