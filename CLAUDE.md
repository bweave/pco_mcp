# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Server Management
- `./bin/dev` - Start development server with auto-reloading (uses rerun with rackup)
- `bundle exec rackup config.ru` - Start server manually
- `./bin/console` - Launch IRB console with app environment loaded

### Database Operations
- `bundle exec rake db:create` - Create database
- `bundle exec rake db:migrate` - Run migrations
- `bundle exec rake db:rollback` - Rollback last migration

### OAuth Setup
- `bundle exec rake oauth:create_test_app` - Create test OAuth application with client credentials

### Code Quality
- `bundle exec rubocop` - Run linting (uses rubocop-rails-omakase)

## Architecture Overview

This is a Ruby/Sinatra-based MCP (Model Context Protocol) server that provides secure access to Planning Center Online data through OAuth authentication.

### Key Components

**MCP Integration Layer**
- `McpController` - Main MCP protocol handler requiring OAuth token authentication
- `app/mcp/people_search_tool.rb` - MCP tool for searching Planning Center people data
- Resource handling for person profiles via `people://person/{id}` URIs

**OAuth Flow Architecture**
- Dual OAuth implementation: acts as OAuth server (for MCP clients) AND OAuth client (to Planning Center)
- `OauthController` - Manages OAuth server endpoints for MCP client authentication
- `PlanningCenterHelpers` - Handles OAuth client calls to Planning Center API with automatic token refresh

**Data Models**
- `Account` - Links OAuth users to Planning Center authentication state
- `PlanningCenterToken` - Stores Planning Center OAuth tokens with refresh capability
- OAuth models (`OauthApplication`, `OauthToken`, `OauthGrant`) - Manages OAuth server state

**Environment-Aware API Endpoints**
Planning Center API URLs switch based on `SINATRA_ENV`:
- `development` → `http://api.pco.test`
- `staging` → `https://api-staging.planningcenteronline.com`
- `production` → `https://api.planningcenteronline.com`

### Application Structure

**Request Flow**
1. MCP clients authenticate via OAuth to get access tokens
2. Authenticated requests to `POST /` trigger MCP protocol handling
3. MCP server validates OAuth tokens and Planning Center authentication
4. Tools make API calls to Planning Center using stored Planning Center tokens
5. Results returned via MCP protocol responses

**Controller Hierarchy**
- `ApplicationController` - Base Sinatra controller with session management and logging
- All other controllers inherit from ApplicationController
- Helper modules (`OauthHelpers`, `PlanningCenterHelpers`) mixed into ApplicationController

**File Loading Order** (in `config/environment.rb`)
1. ApplicationController loaded first
2. All other app files loaded recursively
3. Helper modules included into ApplicationController after all files loaded

### Database Configuration

- Development: SQLite3
- Production: MySQL2
- Uses Sinatra ActiveRecord extension for database connectivity
- Database config driven by `SINATRA_ENV` environment variable