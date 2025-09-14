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
end
