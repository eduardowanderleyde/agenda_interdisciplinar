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

ActiveRecord::Schema[7.1].define(version: 2025_05_06_200521) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "professional_id", null: false
    t.datetime "start_time"
    t.integer "duration"
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "room_id", null: false
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["professional_id"], name: "index_appointments_on_professional_id"
    t.index ["room_id"], name: "index_appointments_on_room_id"
  end

  create_table "evolutions", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.text "content"
    t.text "next_steps"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_evolutions_on_appointment_id"
  end

  create_table "patient_specialties", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "specialty_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id", "specialty_id"], name: "index_patient_specialties_unique", unique: true
    t.index ["patient_id"], name: "index_patient_specialties_on_patient_id"
    t.index ["specialty_id"], name: "index_patient_specialties_on_specialty_id"
  end

  create_table "patients", force: :cascade do |t|
    t.string "name"
    t.date "birthdate"
    t.string "diagnosis"
    t.text "observations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "responsible"
  end

  create_table "professional_specialties", force: :cascade do |t|
    t.bigint "professional_id", null: false
    t.bigint "specialty_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professional_id", "specialty_id"], name: "index_professional_specialties_unique", unique: true
    t.index ["professional_id"], name: "index_professional_specialties_on_professional_id"
    t.index ["specialty_id"], name: "index_professional_specialties_on_specialty_id"
  end

  create_table "professionals", force: :cascade do |t|
    t.string "name"
    t.string "specialty"
    t.json "available_days"
    t.json "available_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rooms_on_name", unique: true
  end

  create_table "specialties", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_specialties_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "appointments", "patients"
  add_foreign_key "appointments", "professionals"
  add_foreign_key "appointments", "rooms"
  add_foreign_key "evolutions", "appointments"
  add_foreign_key "patient_specialties", "patients"
  add_foreign_key "patient_specialties", "specialties"
  add_foreign_key "professional_specialties", "professionals"
  add_foreign_key "professional_specialties", "specialties"
end
