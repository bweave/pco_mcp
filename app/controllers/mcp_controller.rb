class McpController < ApplicationController
  before do
    @account = find_account_by_oauth_token
    halt 401, { error: "invalid_token" }.to_json unless @account
    halt 403, { error: "planning_center_not_authenticated" }.to_json unless account.planning_center_authenticated?
    halt 403, { error: "planning_center_token_expired" }.to_json unless account.planning_center_token.valid?
  end

  post "/" do
    content_type :json

    server = MCP::Server.new(
      name: "pco_mcp",
      title: "Planning Center MCP",
      version: "1.0.0",
      instructions: "Use the tools and prompts to interact with Planning Center data.",
      tools: [ MyTool ],
      resources: [],
      resource_templates: [],
      prompts: [],
      server_context: { current_user_id: @account.planning_center_id }
    )

    server.handle_json(request.body.read)
  end
end
