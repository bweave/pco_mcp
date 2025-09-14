class CreatePlanningCenterTokens < ActiveRecord::Migration[7.2]
  def change
    # Planning Center OAuth tokens per user
    create_table :planning_center_tokens do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.text :access_token, null: false
      t.text :refresh_token
      t.datetime :expires_at
      t.string :scopes
      t.timestamps
    end
  end
end
