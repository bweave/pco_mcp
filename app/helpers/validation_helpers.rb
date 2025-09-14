module ValidationHelpers
  def require_json_body!
    begin
      JSON.parse(request.body.read)
    rescue JSON::ParserError
      halt 400, { error: "invalid_request", error_description: "Invalid JSON" }.to_json
    end
  end

  def require_json_rpc_body!
    begin
      JSON.parse(request.body.read)
    rescue JSON::ParserError => e
      halt 400, {
        jsonrpc: "2.0",
        error: { code: -32700, message: "Parse error" },
        id: nil
      }.to_json
    end
  end

  def require_json_rpc_version!(request_data)
    unless request_data["jsonrpc"] == "2.0"
      halt 400, {
        jsonrpc: "2.0",
        error: { code: -32600, message: "Invalid Request" },
        id: request_data["id"]
      }.to_json
    end
  end

  def require_oauth_authorization_params!(params)
    client_id = params[:client_id] || params["client_id"]
    redirect_uri = params[:redirect_uri] || params["redirect_uri"]
    state = params[:state] || params["state"]
    code_challenge = params[:code_challenge] || params["code_challenge"]
    code_challenge_method = params[:code_challenge_method] || params["code_challenge_method"] || "S256"
    response_type = params[:response_type] || params["response_type"]

    halt 400, { error: "invalid_request", error_description: "missing client_id" }.to_json unless client_id
    halt 400, { error: "invalid_request", error_description: "missing redirect_uri" }.to_json unless redirect_uri
    halt 400, { error: "invalid_request", error_description: "unsupported_response_type" }.to_json unless response_type == "code"
    halt 400, { error: "invalid_request", error_description: "missing code_challenge for PKCE" }.to_json unless code_challenge

    [ client_id, redirect_uri, state, code_challenge, code_challenge_method ]
  end

  def require_oauth_token_params!(params)
    grant_type = params[:grant_type] || params["grant_type"]
    code = params[:code] || params["code"]
    redirect_uri = params[:redirect_uri] || params["redirect_uri"]
    code_verifier = params[:code_verifier] || params["code_verifier"]

    halt 400, { error: "unsupported_grant_type" }.to_json unless grant_type == "authorization_code"
    halt 400, { error: "invalid_request", error_description: "missing code" }.to_json unless code
    halt 400, { error: "invalid_request", error_description: "missing code_verifier" }.to_json unless code_verifier
    halt 400, { error: "invalid_request", error_description: "missing redirect_uri" }.to_json unless redirect_uri

    [ code, redirect_uri, code_verifier ]
  end

  def require_oauth_session!(oauth_request)
    halt 400, { error: "invalid_request", error_description: "no pending oauth request" }.to_json unless oauth_request
  end

  def require_oauth_authorization_code!(code)
    halt 400, { error: "invalid_request", error_description: "missing authorization code" }.to_json unless code
  end

  def require_valid_oauth_grant_for_exchange!(grant, redirect_uri)
    halt 400, { error: "invalid_grant" }.to_json unless grant.valid_for_exchange?
    halt 400, { error: "invalid_grant" }.to_json unless grant.redirect_uri == redirect_uri
  end

  def require_valid_pkce!(code_verifier, code_challenge, code_challenge_method)
    unless verify_pkce_challenge(code_verifier, code_challenge, code_challenge_method)
      halt 400, { error: "invalid_grant", error_description: "PKCE verification failed" }.to_json
    end
  end
end
