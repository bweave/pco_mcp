class ApiController < ApplicationController
  # Get user info
  get "/me" do
    content_type :json
    account = require_oauth_token

    {
      id: account.planning_center_id,
      email: account.email,
      name: account.name,
      planning_center_authenticated: account.planning_center_authenticated?
    }.to_json
  end

  # Proxy to Planning Center People API
  # TODO: this is a placeholder for future resources and tools
  get "/people/*" do
    content_type :json
    account = require_oauth_token
    require_planning_center_account_authentication(account)
    <<~HTML
    <h1>People API Proxy Not Implemented</h1>
    HTML
  end
end