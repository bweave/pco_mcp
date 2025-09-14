class McpController < ApplicationController
  # Main MCP JSON-RPC endpoint
  post "/" do
    content_type :json
    account = require_oauth_token

    begin
      request_data = JSON.parse(request.body.read)
    rescue JSON::ParserError => e
      halt 400, {
        jsonrpc: "2.0",
        error: { code: -32700, message: "Parse error" },
        id: nil
      }.to_json
    end

    # Basic JSON-RPC validation
    unless request_data["jsonrpc"] == "2.0"
      halt 400, {
        jsonrpc: "2.0",
        error: { code: -32600, message: "Invalid Request" },
        id: request_data["id"]
      }.to_json
    end

    method = request_data["method"]
    params = request_data["params"] || {}
    id = request_data["id"]

    case method
    when "initialize"
      {
        jsonrpc: "2.0",
        result: {
          protocolVersion: "2024-11-05",
          capabilities: {
            resources: {},
            tools: {}
          },
          serverInfo: {
            name: "Planning Center MCP Server",
            version: "1.0.0"
          }
        },
        id: id
      }.to_json
    when "notifications/initialized"
      # No response needed for notification
      status 204
    when "resources/list"
      {
        jsonrpc: "2.0",
        result: {
          resources: [
            {
              uri: "planning-center://people/me",
              name: "My Profile",
              description: "Your Planning Center profile information",
              mimeType: "application/json"
            }
          ]
        },
        id: id
      }.to_json
    when "resources/read"
      uri = params["uri"]
      case uri
      when "planning-center://people/me"
        {
          jsonrpc: "2.0",
          result: {
            contents: [
              {
                uri: uri,
                mimeType: "application/json",
                text: {
                  id: account.planning_center_id,
                  email: account.email,
                  name: account.name,
                  planning_center_authenticated: account.planning_center_authenticated?
                }.to_json
              }
            ]
          },
          id: id
        }.to_json
      else
        halt 404, {
          jsonrpc: "2.0",
          error: { code: -32602, message: "Resource not found" },
          id: id
        }.to_json
      end
    else
      halt 404, {
        jsonrpc: "2.0",
        error: { code: -32601, message: "Method not found" },
        id: id
      }.to_json
    end
  end
end