class CreateOauthApplications < ActiveRecord::Migration[7.2]
  def change
    # OAuth applications for MCP clients
    create_table :oauth_applications do |t|
      t.string :name, null: false
      t.string :uid, null: false, index: { unique: true }
      t.string :secret, null: false
      t.text :redirect_uri, null: false
      t.string :scopes, null: false, default: ""
      t.boolean :confidential, null: false, default: true
      t.timestamps
    end
  end
end
