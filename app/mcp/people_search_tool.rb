class PeopleSearchTool < MCP::Tool
  title "People Search Tool"
  description <<~DESCRIPTION
    Search for people in the current organization. Returns up to 25 results at a time, so result set may not be comprehensive.
    Use specific filters (first_name, last_name, email, phone_number) to narrow results when desired. All filters support partial matching.
    When use sort order when finding recently created or updated people.
    When fetching multiple people by ID, prefer to batch calls.
  DESCRIPTION
  input_schema(
    properties: {
      ids: { type: "array", items: { type: "integer" }, description: "Specific person IDs to retrieve" },
      first_name: { type: "string", description: "Filter people by first name" },
      last_name: { type: "string", description: "Filter people by last name" },
      email: { type: "string", description: "Filter people by email" },
      phone_number: { type: "string", description: "Filter people by phone number" },
      per_page: { type: "integer", description: "Maximum number of results to return (default: 10, max: 1000)", minimum: 1, maximum: 1000 },
      sort: { type: "string", description: "Sort configuration as order=created_at for ascending or order=-created_at for descending." }
    },
    required: []
  )
  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  def self.call(ids: nil, first_name: nil, last_name: nil, email: nil, phone_number: nil, per_page: 10, sort: nil, server_context:)
    account = server_context[:account]
    params = {}

    if ids && ids.any?
      params["where[id]"] = ids.join(",")
    else
      if first_name || last_name || email
        search_terms = [ first_name, last_name, email ].compact.join(" ")
        params["where[search_name_or_email]"] = search_terms unless search_terms.empty?
      end

      if phone_number
        params["where[phone_number]"] = phone_number
      end
    end

    params["per_page"] = per_page
    params["order"] = sort if sort

    person_fields = %w[first_name last_name name gender birthdate status created_at updated_at]
    response = account.extend(PlanningCenterHelpers).make_planning_center_request(
      account,
      "/people/v2/people?include=emails,phone_numbers&fields[Person]=#{person_fields.join(",")}",
      params: params
    )

    # Format and return response
    format_response(response)
  end

  private

  def self.format_response(response)
    if response.nil?
      return MCP::Tool::Response.new([
        { type: "text", text: "Error: Unable to fetch people data from Planning Center API" }
      ])
    end

    if response["data"].nil? || response["data"].empty?
      return MCP::Tool::Response.new([
        { type: "text", text: "No people found matching the search criteria" }
      ])
    end

    included_data = response["included"]
      .group_by { |item| item["type"] }
      .transform_values do |items|
        items.map do |item|
          {
            id: item["id"],
            person_id: item.dig("relationships", "person", "data", "id"),
            attributes: item["attributes"]
          }
        end.group_by { |item| item[:person_id] }
      end

    people_data = response["data"].map do |person|
      attributes = person["attributes"] || {}
      email = included_data["Email"][person["id"]]&.first&.dig(:attributes, "address")
      phone =  included_data["PhoneNumber"][person["id"]]&.first&.dig(:attributes, "number")

      {
        id: person["id"],
        name: attributes["name"],
        first_name: attributes["first_name"],
        last_name: attributes["last_name"],
        gender: attributes["gender"],
        birthdate: attributes["birthdate"],
        status: attributes["status"],
        email:,
        phone:,
        created_at: attributes["created_at"],
        updated_at: attributes["updated_at"]
      }
    end

    MCP::Tool::Response.new([
      {
        type: "text",
        text: { found: people_data.length, people: people_data }.to_json
      }
    ])
  end
end
