module AuthenticationHelpers
  def require_planning_center_account_authentication(account)
    halt 403, { error: "planning_center_not_authenticated" }.to_json unless account.planning_center_authenticated?
    halt 403, { error: "planning_center_token_expired" }.to_json unless account.planning_center_token.valid?
  end
end
