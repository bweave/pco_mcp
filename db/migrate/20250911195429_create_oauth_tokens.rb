class CreateOauthTokens < ActiveRecord::Migration[7.2]
  def change
    # OAuth access tokens for MCP clients
    create_table :oauth_tokens do |t|
      t.references :oauth_application, null: false, foreign_key: true
      t.references :account, null: true, foreign_key: true
      t.string :token, null: false, index: { unique: true }
      t.string :refresh_token, index: { unique: true }
      t.integer :expires_in
      t.string :scopes
      t.datetime :created_at, null: false
      t.datetime :revoked_at
    end
  end
end
