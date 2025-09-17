class MyTool < MCP::Tool
  title "My Tool" # WARNING: This is a `Draft` and is not supported in the `Version 2025-06-18 (latest)` specification.
  description "This tool performs specific functionality..."
  input_schema(
    properties: {
      message: { type: "string" }
    },
    required: [ "message" ]
  )
  output_schema(
    properties: {
      result: { type: "string" },
      success: { type: "boolean" },
      timestamp: { type: "string", format: "date-time" }
    },
    required: [ "result", "success", "timestamp" ]
  )
  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false,
    title: "My Tool"
  )

  def self.call(message:, server_context:)
    MCP::Tool::Response.new([ { type: "text", text: "OK -- PCO ID: #{server_context[:current_user_id]}" } ])
  end
end
