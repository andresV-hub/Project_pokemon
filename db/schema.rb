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

ActiveRecord::Schema[8.1].define(version: 2026_09_02_204613) do
  create_table "inventory_items", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "kind"], name: "index_inventory_items_on_user_id_and_kind", unique: true
    t.index ["user_id"], name: "index_inventory_items_on_user_id"
  end

  create_table "pokedex_sightings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "num_pokedex", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "num_pokedex"], name: "index_pokedex_sightings_on_user_id_and_num_pokedex", unique: true
    t.index ["user_id"], name: "index_pokedex_sightings_on_user_id"
  end

  create_table "pokemons", charset: "utf8mb3", force: :cascade do |t|
    t.integer "atack"
    t.string "atack0"
    t.string "atack1"
    t.string "atack2"
    t.string "atack3"
    t.integer "base_happiness"
    t.integer "capture_rate"
    t.integer "damage", default: 0, null: false
    t.integer "defense"
    t.text "description"
    t.integer "experience", default: 0, null: false
    t.string "growth_rate"
    t.string "habitat"
    t.integer "hp"
    t.text "image"
    t.integer "level", default: 5, null: false
    t.string "name"
    t.string "nickname"
    t.integer "num_pokedex"
    t.integer "party_position"
    t.string "pending_move"
    t.boolean "shiny", default: false, null: false
    t.integer "special_atack"
    t.integer "special_defense"
    t.integer "speed"
    t.string "type_of_pokemon"
    t.bigint "user_id"
    t.index ["user_id", "party_position"], name: "index_pokemons_on_user_id_and_party_position", unique: true
    t.index ["user_id"], name: "index_pokemons_on_user_id"
  end

  create_table "roles", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "solid_cache_entries", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", limit: 1024, null: false
    t.bigint "key_hash", null: false
    t.binary "value", size: :long, null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "AddFieldsToUser"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "last_name"
    t.integer "money", default: 0, null: false
    t.string "name"
    t.integer "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "inventory_items", "users"
  add_foreign_key "pokedex_sightings", "users"
  add_foreign_key "users_roles", "roles"
  add_foreign_key "users_roles", "users"
end
