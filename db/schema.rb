# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_09_11_195445) do
  create_table "accounts", force: :cascade do |t|
    t.string "email", null: false
    t.string "planning_center_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["planning_center_id"], name: "index_accounts_on_planning_center_id", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_grants", force: :cascade do |t|
    t.integer "oauth_application_id", null: false
    t.integer "account_id", null: false
    t.string "code", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: ""
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.string "planning_center_state"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["account_id"], name: "index_oauth_grants_on_account_id"
    t.index ["code"], name: "index_oauth_grants_on_code", unique: true
    t.index ["oauth_application_id"], name: "index_oauth_grants_on_oauth_application_id"
  end

  create_table "oauth_tokens", force: :cascade do |t|
    t.integer "oauth_application_id", null: false
    t.integer "account_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["account_id"], name: "index_oauth_tokens_on_account_id"
    t.index ["oauth_application_id"], name: "index_oauth_tokens_on_oauth_application_id"
    t.index ["refresh_token"], name: "index_oauth_tokens_on_refresh_token", unique: true
    t.index ["token"], name: "index_oauth_tokens_on_token", unique: true
  end

  create_table "planning_center_tokens", force: :cascade do |t|
    t.integer "account_id", null: false
    t.text "access_token", null: false
    t.text "refresh_token"
    t.datetime "expires_at"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_planning_center_tokens_on_account_id", unique: true
  end

  add_foreign_key "oauth_grants", "accounts"
  add_foreign_key "oauth_grants", "oauth_applications"
  add_foreign_key "oauth_tokens", "accounts"
  add_foreign_key "oauth_tokens", "oauth_applications"
  add_foreign_key "planning_center_tokens", "accounts"
end
