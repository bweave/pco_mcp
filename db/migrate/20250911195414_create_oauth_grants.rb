class CreateOauthGrants < ActiveRecord::Migration[7.2]
  def change
    # OAuth authorization grants (PKCE flow)
    create_table :oauth_grants do |t|
      t.references :oauth_application, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :code, null: false, index: { unique: true }
      t.integer :expires_in, null: false
      t.text :redirect_uri, null: false
      t.string :scopes, default: ""
      t.string :code_challenge
      t.string :code_challenge_method
      t.string :planning_center_state # For correlating with PC OAuth flow
      t.datetime :created_at, null: false
      t.datetime :revoked_at
    end
  end
end
