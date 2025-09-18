class McpController < ApplicationController
  before do
    @account = find_account_by_oauth_token
    halt 401, { error: "invalid_token" }.to_json unless @account
    halt 403, { error: "planning_center_not_authenticated" }.to_json unless @account.planning_center_authenticated?
    halt 403, { error: "planning_center_token_expired" }.to_json unless @account.planning_center_token.valid?
  end

  post "/" do
    content_type :json

    server = MCP::Server.new(
      name: "pco_mcp",
      title: "Planning Center MCP",
      version: "1.0.0",
      instructions: "Use the tools and prompts to interact with Planning Center data.",
      tools: [ PeopleSearchTool ],
      resources: [],
      resource_templates: [],
      prompts: [],
      server_context: {
        current_user_id: @account.planning_center_id,
        account: @account
      }
    )

    server.resources_read_handler do |params|
      handle_resource_read(params[:uri])
    end

    server.handle_json(request.body.read)
  end

  private

  def handle_resource_read(uri)
    case uri
    when %r{^people://person/([A-Z0-9]+)$}
      id = ::Regexp.last_match(1)
      content = PersonProfileResource.read(id: id.gsub("AC", ""))

      [ {
        uri:,
        mimeType: "application/json",
        text: JSON.pretty_generate(content)
      } ]
    else
      [ {
        uri:,
        mimeType: "application/json",
        text: JSON.pretty_generate({ error: "Resource not found" })
      } ]
    end
  end
end
