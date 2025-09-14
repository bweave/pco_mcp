class OauthController < ApplicationController
  # OAuth discovery endpoint
  get "/.well-known/oauth-authorization-server" do
    content_type :json
    {
      issuer: request.base_url.to_s,
      authorization_endpoint: "#{request.base_url}/oauth/authorize",
      token_endpoint: "#{request.base_url}/oauth/token",
      registration_endpoint: "#{request.base_url}/oauth/register",
      response_types_supported: [ "code" ],
      grant_types_supported: [ "authorization_code", "refresh_token" ],
      code_challenge_methods_supported: [ "S256" ],
      scopes_supported: [ "planning_center:read", "planning_center:write" ],
      token_endpoint_auth_methods_supported: [ "none" ] # PKCE clients don't need client authentication
    }.to_json
  end

  post "/register" do
    content_type :json

    request_body = require_json_body!

    client_name = request_body["client_name"]
    redirect_uris = request_body["redirect_uris"]
    application_type = request_body["application_type"] || "native" # MCP clients are typically native apps

    # Create OAuth application (non-confidential for PKCE)
    application = OauthApplication.create!(
      name: client_name,
      redirect_uri: redirect_uris.first, # Store primary redirect URI
      scopes: "planning_center:read planning_center:write",
      confidential: false # Always public for MCP clients using PKCE
    )

    {
      client_id: application.uid,
      client_name: application.name,
      redirect_uris: [ application.redirect_uri ],
      grant_types: [ "authorization_code", "refresh_token" ],
      response_types: [ "code" ],
      application_type: application_type,
      token_endpoint_auth_method: "none",
      require_auth_time: false,
      default_scopes: application.scopes.split(" ")
    }.to_json
  end

  # OAuth Authorization endpoint - initiates Planning Center OAuth
  get "/authorize" do
    client_id, redirect_uri, state, scope, code_challenge, code_challenge_method = require_oauth_authorization_params!(params)

    # Find OAuth application
    application = OauthApplication.find_by!(uid: client_id)

    # Store OAuth request in session for Planning Center flow
    session[:oauth_request] = {
      client_id: client_id,
      redirect_uri: redirect_uri,
      state: state,
      code_challenge: code_challenge,
      code_challenge_method: code_challenge_method,
      scope: scope,
      application_id: application.id
    }

    # Redirect to Planning Center OAuth
    planning_center_scopes = PlanningCenterToken::PLANNING_CENTER_SCOPES.join(" ")
    planning_center_auth_url = "#{planning_center_api_url}/oauth/authorize?" \
                              "client_id=#{ENV['PLANNING_CENTER_CLIENT_ID']}&" \
                              "redirect_uri=#{CGI.escape("#{request.base_url}/oauth/planning_center/callback")}&" \
                              "response_type=code&" \
                              "scope=#{CGI.escape(planning_center_scopes)}&" \
                              "state=#{SecureRandom.hex(16)}"

    redirect planning_center_auth_url
  end

  # Planning Center OAuth callback - completes the flow
  get "/planning_center/callback" do
    oauth_request = session[:oauth_request]
    require_oauth_session!(oauth_request)

    error = params[:error]
    if error
      # Return error to MCP client
      logger.info "OAuth error from Planning Center: #{error}"
      redirect "#{oauth_request[:redirect_uri]}?error=#{error}&state=#{oauth_request[:state]}"
    end

    code = params[:code]
    require_oauth_authorization_code!(code)

    # Exchange code for Planning Center tokens
    planning_center_client = create_planning_center_client
    callback_uri = "#{request.base_url}/oauth/planning_center/callback"

    begin
      token_response = planning_center_client.auth_code.get_token(
        code,
        redirect_uri: callback_uri
      )

      user_response = token_response.get("/people/v2/me?include=emails", headers: {
        "Accept" => "application/vnd.api+json",
        "Content-Type" => "application/vnd.api+json"
      })
      user_data = JSON.parse(user_response.body)
      account = Account.find_or_create_by(planning_center_id: user_data.dig("data", "id")) do |acc|
        acc.email = user_data["included"].find { |inc| inc["type"] == "Email" }.dig("attributes", "address")
        acc.name = user_data.dig("data", "attributes", "name")
      end

      planning_center_token = account.planning_center_token || account.build_planning_center_token
      planning_center_token.assign_attributes(
        access_token: token_response.token,
        refresh_token: token_response.refresh_token,
        expires_at: token_response.expires_at ? Time.at(token_response.expires_at) : nil,
        scopes: PlanningCenterToken::PLANNING_CENTER_SCOPES.join(" ")
      )
      planning_center_token.save!

      # Create OAuth grant for MCP client
      application = OauthApplication.find(oauth_request[:application_id])
      grant = OauthGrant.create!(
        oauth_application: application,
        account: account,
        expires_in: 600, # 10 minutes
        redirect_uri: oauth_request[:redirect_uri],
        scopes: oauth_request[:scope],
        code_challenge: oauth_request[:code_challenge],
        code_challenge_method: oauth_request[:code_challenge_method]
      )

      # Clear session
      session.delete(:oauth_request)

      # Redirect back to MCP client with authorization code
      redirect "#{oauth_request[:redirect_uri]}?code=#{grant.code}&state=#{oauth_request[:state]}"
    rescue OAuth2::Error => e
      logger.error "Planning Center OAuth error: #{e.message}"
      logger.error "OAuth2 Error details:"
      logger.error "  Code: #{e.code}"
      logger.error "  Description: #{e.description}"
      logger.error "  Response: #{e.response.body if e.response}"
      logger.error "  Response Headers: #{e.response.headers if e.response}"

      redirect "#{oauth_request[:redirect_uri]}?error=server_error&error_description=#{CGI.escape(e.message)}&state=#{oauth_request[:state]}"
    end
  end

  # OAuth Token endpoint
  post "/token" do
    content_type :json

    code, redirect_uri, code_verifier = require_oauth_token_params!(params)

    # Find the grant
    grant = OauthGrant.find_by!(code: code)
    require_valid_oauth_grant_for_exchange!(grant, redirect_uri)

    # Verify PKCE
    require_valid_pkce!(code_verifier, grant.code_challenge, grant.code_challenge_method)

    # Create access token
    access_token = OauthToken.create!(
      oauth_application: grant.oauth_application,
      account: grant.account,
      expires_in: OauthToken::EXPIRES_IN,
      scopes: grant.scopes
    )

    # Revoke the grant
    grant.revoke!

    {
      access_token: access_token.token,
      token_type: "Bearer",
      expires_in: access_token.expires_in,
      scope: access_token.scopes
    }.to_json
  end
end

