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

ActiveRecord::Schema[8.1].define(version: 2026_09_17_190003) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "courts", force: :cascade do |t|
    t.decimal "base_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.boolean "is_active"
    t.string "name"
    t.integer "pricing_scheme_id"
    t.integer "sport_id", null: false
    t.integer "sports_complex_id", null: false
    t.string "surface_type"
    t.datetime "updated_at", null: false
    t.index ["pricing_scheme_id"], name: "index_courts_on_pricing_scheme_id"
    t.index ["sport_id"], name: "index_courts_on_sport_id"
    t.index ["sports_complex_id"], name: "index_courts_on_sports_complex_id"
  end

  create_table "pricing_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "end_time", null: false
    t.decimal "multiplier", precision: 4, scale: 2, default: "1.0", null: false
    t.integer "pricing_scheme_id", null: false
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["pricing_scheme_id", "day_of_week"], name: "index_pricing_rules_on_pricing_scheme_id_and_day_of_week"
    t.index ["pricing_scheme_id"], name: "index_pricing_rules_on_pricing_scheme_id"
  end

  create_table "pricing_schemes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reservations", force: :cascade do |t|
    t.integer "court_id", null: false
    t.datetime "created_at", null: false
    t.time "end_time"
    t.date "reservation_date"
    t.time "start_time"
    t.integer "status"
    t.decimal "total_price"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["court_id"], name: "index_reservations_on_court_id"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "sports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sports_on_name", unique: true
  end

  create_table "sports_complexes", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.integer "default_pricing_scheme_id"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["default_pricing_scheme_id"], name: "index_sports_complexes_on_default_pricing_scheme_id"
  end

  create_table "time_slots", force: :cascade do |t|
    t.integer "court_id", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week"
    t.time "end_time"
    t.decimal "price"
    t.decimal "price_multiplier", precision: 4, scale: 2, default: "1.0", null: false
    t.time "start_time"
    t.datetime "updated_at", null: false
    t.index ["court_id"], name: "index_time_slots_on_court_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.string "phone"
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "courts", "pricing_schemes"
  add_foreign_key "courts", "sports"
  add_foreign_key "courts", "sports_complexes"
  add_foreign_key "pricing_rules", "pricing_schemes", on_delete: :cascade
  add_foreign_key "reservations", "courts"
  add_foreign_key "reservations", "users"
  add_foreign_key "sports_complexes", "pricing_schemes", column: "default_pricing_scheme_id"
  add_foreign_key "time_slots", "courts"
end
