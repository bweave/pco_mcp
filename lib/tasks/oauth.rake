namespace :oauth do
  desc "Create a test OAuth application"
  task :create_test_app do
    app = OauthApplication.create!(
      name: "Test MCP Client",
      redirect_uri: "http://localhost:3000/callback",
      scopes: "planning_center:read planning_center:write",
      confidential: false # PKCE requires non-confidential clients
    )

    puts "Created OAuth Application:"
    puts "  Name: #{app.name}"
    puts "  Client ID: #{app.uid}"
    puts "  Client Secret: #{app.secret}"
    puts "  Redirect URI: #{app.redirect_uri}"
    puts "  Confidential: #{app.confidential}"
    puts ""
    puts "Use this Client ID in your MCP client configuration:"
    puts "  client_id: #{app.uid}"
  end
end
