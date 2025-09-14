class McpController < ApplicationController
  include PlanningCenterHelpers
  # Main MCP JSON-RPC endpoint
  post "/" do
    content_type :json
    account = require_oauth_token

    request_data = require_json_rpc_body!

    # Basic JSON-RPC validation
    require_json_rpc_version!(request_data)

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
      resources = [
        {
          uri: "planning-center://people/me",
          name: "My Profile",
          description: "Your Planning Center profile information",
          mimeType: "application/json"
        }
      ]

      # Add additional resources if user is authenticated with Planning Center
      if account.planning_center_authenticated?
        resources += [
          {
            uri: "planning-center://people/households",
            name: "Households",
            description: "List of households you have access to",
            mimeType: "application/json"
          },
          {
            uri: "planning-center://people/people",
            name: "People",
            description: "List of people you have access to",
            mimeType: "application/json"
          },
          {
            uri: "planning-center://people/field_definitions",
            name: "Field Definitions",
            description: "Available custom field definitions",
            mimeType: "application/json"
          },
          {
            uri: "planning-center://people/lists",
            name: "Lists",
            description: "Available people lists",
            mimeType: "application/json"
          }
        ]
      end

      {
        jsonrpc: "2.0",
        result: { resources: resources },
        id: id
      }.to_json
    when "resources/read"
      uri = params["uri"]
      case uri
      when "planning-center://people/me"
        profile_data = if account.planning_center_authenticated?
                        api_response = make_planning_center_request(account, "/people/v2/me")
                        if api_response && api_response["data"]
                          api_response["data"]["attributes"].merge(
                            id: account.planning_center_id,
                            planning_center_authenticated: true
                          )
                        else
                          {
                            id: account.planning_center_id,
                            email: account.email,
                            name: account.name,
                            planning_center_authenticated: true,
                            error: "Unable to fetch detailed profile from Planning Center"
                          }
                        end
                      else
                        {
                          id: account.planning_center_id,
                          email: account.email,
                          name: account.name,
                          planning_center_authenticated: false
                        }
                      end

        {
          jsonrpc: "2.0",
          result: {
            contents: [
              {
                uri: uri,
                mimeType: "application/json",
                text: profile_data.to_json
              }
            ]
          },
          id: id
        }.to_json

      when "planning-center://people/households"
        unless account.planning_center_authenticated?
          halt 401, {
            jsonrpc: "2.0",
            error: { code: -32000, message: "Planning Center authentication required" },
            id: id
          }.to_json
        end

        api_response = make_planning_center_request(account, "/people/v2/households", params: { limit: 25 })
        households_data = api_response ? api_response : { error: "Unable to fetch households from Planning Center" }

        {
          jsonrpc: "2.0",
          result: {
            contents: [
              {
                uri: uri,
                mimeType: "application/json",
                text: households_data.to_json
              }
            ]
          },
          id: id
        }.to_json

      when "planning-center://people/people"
        unless account.planning_center_authenticated?
          halt 401, {
            jsonrpc: "2.0",
            error: { code: -32000, message: "Planning Center authentication required" },
            id: id
          }.to_json
        end

        api_response = make_planning_center_request(account, "/people/v2/people", params: { limit: 25 })
        people_data = api_response ? api_response : { error: "Unable to fetch people from Planning Center" }

        {
          jsonrpc: "2.0",
          result: {
            contents: [
              {
                uri: uri,
                mimeType: "application/json",
                text: people_data.to_json
              }
            ]
          },
          id: id
        }.to_json

      when "planning-center://people/field_definitions"
        unless account.planning_center_authenticated?
          halt 401, {
            jsonrpc: "2.0",
            error: { code: -32000, message: "Planning Center authentication required" },
            id: id
          }.to_json
        end

        api_response = make_planning_center_request(account, "/people/v2/field_definitions")
        field_definitions_data = api_response ? api_response : { error: "Unable to fetch field definitions from Planning Center" }

        {
          jsonrpc: "2.0",
          result: {
            contents: [
              {
                uri: uri,
                mimeType: "application/json",
                text: field_definitions_data.to_json
              }
            ]
          },
          id: id
        }.to_json

      when "planning-center://people/lists"
        unless account.planning_center_authenticated?
          halt 401, {
            jsonrpc: "2.0",
            error: { code: -32000, message: "Planning Center authentication required" },
            id: id
          }.to_json
        end

        api_response = make_planning_center_request(account, "/people/v2/lists")
        lists_data = api_response ? api_response : { error: "Unable to fetch lists from Planning Center" }

        {
          jsonrpc: "2.0",
          result: {
            contents: [
              {
                uri: uri,
                mimeType: "application/json",
                text: lists_data.to_json
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

