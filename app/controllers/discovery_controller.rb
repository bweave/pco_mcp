class DiscoveryController < ApplicationController
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
end
