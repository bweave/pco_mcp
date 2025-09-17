require "base64"
require "digest"

module OauthHelpers
  def find_account_by_oauth_token
    auth_header = request.env["HTTP_AUTHORIZATION"]
    return nil unless auth_header&.start_with?("Bearer ")

    token_value = auth_header.split(" ", 2)[1]
    token = OauthToken.find_by(token: token_value)

    token&.valid_for_requests? ? token.account : nil
  end

  def verify_pkce_challenge(verifier, challenge, method)
    expected_challenge = generate_pkce_challenge(verifier, method)
    expected_challenge == challenge
  end

  def generate_pkce_challenge(verifier, method = "S256")
    case method
    when "S256"
      Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    when "plain"
      verifier
    else
      raise "Unsupported PKCE method: #{method}"
    end
  end
end
