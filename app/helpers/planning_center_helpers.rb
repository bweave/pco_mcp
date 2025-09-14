module PlanningCenterHelpers
  def planning_center_api_url
    return ENV["PLANNING_CENTER_API_URL"] if ENV["PLANNING_CENTER_API_URL"].present?

    case ENV["SINATRA_ENV"] || ENV["RACK_ENV"] || "development"
    when "development"
      "http://api.pco.test"
    when "staging"
      "https://api-staging.planningcenteronline.com"
    when "production"
      "https://api.planningcenteronline.com"
    else
      "https://api.planningcenteronline.com" # Default to production
    end
  end

  def create_planning_center_client
    OAuth2::Client.new(
      ENV["PLANNING_CENTER_CLIENT_ID"],
      ENV["PLANNING_CENTER_CLIENT_SECRET"],
      site: planning_center_api_url
    )
  end

  def make_planning_center_request(account, path, method: :get, params: {})
    return nil unless account.planning_center_authenticated?

    client = create_planning_center_client
    token = OAuth2::AccessToken.new(client, account.planning_center_token.access_token)

    begin
      response = case method
                when :get
                  token.get(path, params: params)
                when :post
                  token.post(path, body: params.to_json, headers: { "Content-Type" => "application/json" })
                when :put
                  token.put(path, body: params.to_json, headers: { "Content-Type" => "application/json" })
                when :delete
                  token.delete(path)
                else
                  raise ArgumentError, "Unsupported HTTP method: #{method}"
                end

      JSON.parse(response.body)
    rescue OAuth2::Error => e
      Rails.logger.error "Planning Center API error: #{e.message}" if defined?(Rails)
      nil
    rescue StandardError => e
      Rails.logger.error "Unexpected error calling Planning Center API: #{e.message}" if defined?(Rails)
      nil
    end
  end
end
