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

ActiveRecord::Schema[8.1].define(version: 2026_09_03_171547) do
  create_table "courts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active"
    t.string "name"
    t.integer "sport_id", null: false
    t.integer "sports_complex_id", null: false
    t.string "surface_type"
    t.datetime "updated_at", null: false
    t.index ["sport_id"], name: "index_courts_on_sport_id"
    t.index ["sports_complex_id"], name: "index_courts_on_sports_complex_id"
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

  create_table "time_slots", force: :cascade do |t|
    t.integer "court_id", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week"
    t.time "end_time"
    t.decimal "price"
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

  add_foreign_key "courts", "sports"
  add_foreign_key "courts", "sports_complexes"
  add_foreign_key "reservations", "courts"
  add_foreign_key "reservations", "users"
  add_foreign_key "time_slots", "courts"
end
