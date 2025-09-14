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

    begin
      request_body = JSON.parse(request.body.read)
    rescue JSON::ParserError
      halt 400, { error: "invalid_request", error_description: "Invalid JSON" }.to_json
    end

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
    client_id = params[:client_id]
    redirect_uri = params[:redirect_uri]
    response_type = params[:response_type]
    state = params[:state]
    code_challenge = params[:code_challenge]
    code_challenge_method = params[:code_challenge_method] || "S256"
    scope = params[:scope] || "planning_center:read"

    # Validate required parameters
    halt 400, { error: "invalid_request", error_description: "missing client_id" }.to_json unless client_id
    halt 400, { error: "invalid_request", error_description: "missing redirect_uri" }.to_json unless redirect_uri
    halt 400, { error: "invalid_request", error_description: "unsupported_response_type" }.to_json unless response_type == "code"
    halt 400, { error: "invalid_request", error_description: "missing code_challenge for PKCE" }.to_json unless code_challenge

    # Find OAuth application
    application = OauthApplication.find_by(uid: client_id)
    halt 400, { error: "invalid_client" }.to_json unless application

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
    code = params[:code]
    error = params[:error]

    logger.info "Planning Center callback received:"
    logger.info "  Code: #{code}" if code
    logger.info "  Error: #{error}" if error
    logger.info "  All params: #{params.inspect}"
    logger.info "  Request headers: #{request.env.select { |k, v| k.start_with?('HTTP_') }.inspect}"

    oauth_request = session[:oauth_request]
    halt 400, { error: "invalid_request", error_description: "no pending oauth request" }.to_json unless oauth_request

    if error
      # Return error to MCP client
      logger.info "OAuth error from Planning Center: #{error}"
      redirect "#{oauth_request[:redirect_uri]}?error=#{error}&state=#{oauth_request[:state]}"
    end

    halt 400, { error: "invalid_request", error_description: "missing authorization code" }.to_json unless code

    # Exchange code for Planning Center tokens
    planning_center_client = create_planning_center_client
    callback_uri = "#{request.base_url}/oauth/planning_center/callback"

    logger.info "Exchanging code for Planning Center tokens:"
    logger.info "  Code: #{code}"
    logger.info "  Redirect URI: #{callback_uri}"
    logger.info "  Client Site: #{planning_center_client.site}"

    begin
      logger.info "About to exchange authorization code for tokens:"
      logger.info "  Code: #{code[0..20]}..." # Log first 20 chars for security
      logger.info "  Callback URI: #{callback_uri}"
      logger.info "  Planning Center Client Site: #{planning_center_client.site}"
      logger.info "  Client ID: #{ENV['PLANNING_CENTER_CLIENT_ID']}"
      logger.info "  Token endpoint will be: #{planning_center_client.site}/oauth/token"

      token_response = planning_center_client.auth_code.get_token(
        code,
        redirect_uri: callback_uri
      )
      logger.info "OAuth2 get_token succeeded!"
      logger.info "Token response class: #{token_response.class}"
      logger.info "Token present: #{!token_response.token.nil?}"
      logger.info "Refresh token present: #{!token_response.refresh_token.nil?}"
      logger.info "Expires at: #{token_response.expires_at}"

      # Get user info from Planning Center
      logger.info "About to fetch user info from /people/v2/me"
      logger.info "Token client site: #{token_response.client.site}"
      logger.info "Full URL will be: #{token_response.client.site}/people/v2/me"

      # First try the OAuth2 library method
      begin
        logger.info "Trying OAuth2 library get method..."
        user_response = token_response.get('/people/v2/me?include=emails', headers: {
          'Accept' => 'application/vnd.api+json',
          'Content-Type' => 'application/vnd.api+json'
        })
        logger.info "OAuth2 library call succeeded!"
        user_data = JSON.parse(user_response.body)
      rescue OAuth2::Error => e
        logger.error "OAuth2 library call failed: #{e.class}: #{e.message}"
        logger.error "Response: #{e.response.inspect if e.respond_to?(:response)}"
        raise e
      end

      # Create or update account
      account = Account.find_or_create_by(planning_center_id: user_data.dig("data", "id")) do |acc|
        acc.email = user_data["included"].find { |inc| inc["type"] == "Email" }.dig("attributes", "address")
        acc.name = user_data.dig("data", "attributes", "name")
      end

      # Store Planning Center tokens
      pc_token = account.planning_center_token || account.build_planning_center_token
      pc_token.assign_attributes(
        access_token: token_response.token,
        refresh_token: token_response.refresh_token,
        expires_at: token_response.expires_at ? Time.at(token_response.expires_at) : nil,
        scopes: PlanningCenterToken::PLANNING_CENTER_SCOPES.join(" ")
      )
      pc_token.save!

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

    grant_type = params[:grant_type]
    code = params[:code]
    redirect_uri = params[:redirect_uri]
    client_id = params[:client_id]
    client_secret = params[:client_secret]
    code_verifier = params[:code_verifier]

    halt 400, { error: "unsupported_grant_type" }.to_json unless grant_type == "authorization_code"
    halt 400, { error: "invalid_request", error_description: "missing code" }.to_json unless code
    halt 400, { error: "invalid_request", error_description: "missing code_verifier" }.to_json unless code_verifier

    # Find the grant
    grant = OauthGrant.find_by(code: code)
    halt 400, { error: "invalid_grant" }.to_json unless grant
    halt 400, { error: "invalid_grant" }.to_json unless grant.valid_for_exchange?
    halt 400, { error: "invalid_grant" }.to_json unless grant.redirect_uri == redirect_uri

    # Verify PKCE
    unless verify_pkce_challenge(code_verifier, grant.code_challenge, grant.code_challenge_method)
      halt 400, { error: "invalid_grant", error_description: "PKCE verification failed" }.to_json
    end

    # Create access token
    access_token = OauthToken.create!(
      oauth_application: grant.oauth_application,
      account: grant.account,
      # TODO: extract this to a constant in OauthToken and make it longer
      expires_in: 3600, # 1 hour
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