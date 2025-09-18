# Planning Center MCP Server

A Model Context Protocol (MCP) server that provides secure access to Planning Center data through authenticated API endpoints.

## Overview

This Ruby-based MCP server enables AI assistants to interact with Planning Center data via OAuth-authenticated API calls. It provides tools for searching people and accessing person profiles while maintaining secure token-based authentication.

## Features

- **People Search Tool**: Search for people by name, email, phone number, or specific IDs
- **Resource Access**: Read person profile data via MCP resource URIs
- **OAuth Authentication**: Secure token-based authentication with Planning Center
- **Auto-refresh Tokens**: Automatic handling of expired access tokens

## Architecture

Built on:

- **Sinatra** - Web framework
- **ActiveRecord** - Database ORM
- **Rodauth OAuth** - OAuth server implementation
- **MCP Ruby Gem** - Model Context Protocol support

## Installation

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd pco_mcp
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Set up the database:

   ```bash
   bundle exec rake db:create db:migrate
   ```

4. Configure environment variables:

   The application supports environment-specific configuration files:
   - `.env` - Base configuration (all environments)
   - `.env.development` - Development-specific overrides
   - `.env.staging` - Staging environment configuration
   - `.env.production` - Production environment configuration

   Create a `.env` file with:
   ```
   PLANNING_CENTER_CLIENT_ID=your_client_id
   PLANNING_CENTER_CLIENT_SECRET=your_client_secret
   SESSION_SECRET=your_session_secret
   ```

   The server automatically connects to different Planning Center API endpoints based on `SINATRA_ENV`:
   - `development` → `http://api.pco.test`
   - `staging` → `https://api-staging.planningcenteronline.com`
   - `production` → `https://api.planningcenteronline.com`

## Development

Start the development server:

```bash
./bin/dev
```

This runs the server with auto-reloading on file changes.

## Add it to Claude Code

```bash
claude mcp add --scope user --transport http pco_mcp http://localhost:9292
```

## MCP Tools

### People Search Tool

Search for people in the current Planning Center organization:

```json
{
  "tool": "people_search_tool",
  "arguments": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "per_page": 25,
    "sort": "order=created_at"
  }
}
```

Supports filtering by:

- `ids` - Array of specific person IDs
- `first_name` - First name (partial matching)
- `last_name` - Last name (partial matching)
- `email` - Email address (partial matching)
- `phone_number` - Phone number (partial matching)
- `per_page` - Results per page (1-1000, default: 10)
- `sort` - Sort order (e.g., "order=created_at" or "order=-updated_at")

## Database Models

- **Account** - User accounts with Planning Center integration
- **OauthApplication** - OAuth client applications
- **OauthToken** - OAuth access/refresh tokens
- **OauthGrant** - OAuth authorization grants
- **PlanningCenterToken** - Planning Center API tokens

## Code Quality

Run RuboCop for code style checks:

```bash
bundle exec rubocop
```

