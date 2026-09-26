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

ActiveRecord::Schema[8.0].define(version: 2026_09_19_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "app_settings", force: :cascade do |t|
    t.integer "target_count", default: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "charts", force: :cascade do |t|
    t.string "fingerprint"
    t.date "chart_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "songs", force: :cascade do |t|
    t.integer "rank"
    t.string "title"
    t.string "artist"
    t.integer "last_week"
    t.date "chart_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "chart_id", null: false
    t.index ["chart_id"], name: "index_songs_on_chart_id"
  end

  create_table "update_items", force: :cascade do |t|
    t.bigint "update_run_id", null: false
    t.bigint "song_id", null: false
    t.integer "rank", null: false
    t.string "status", default: "pending", null: false
    t.string "apple_title"
    t.string "apple_artist"
    t.string "apple_kind"
    t.string "apple_url"
    t.string "match_result"
    t.datetime "verified_at"
    t.string "error_code"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["song_id"], name: "index_update_items_on_song_id"
    t.index ["update_run_id", "rank"], name: "index_update_items_on_update_run_id_and_rank", unique: true
    t.index ["update_run_id"], name: "index_update_items_on_update_run_id"
  end

  create_table "update_runs", force: :cascade do |t|
    t.bigint "chart_id", null: false
    t.date "target_date", null: false
    t.string "playlist_name", null: false
    t.string "playlist_url"
    t.string "status", default: "ready", null: false
    t.integer "verified_prefix", default: 0, null: false
    t.integer "playlist_count", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "error_code"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "target_count", default: 60, null: false
    t.index ["chart_id"], name: "index_update_runs_on_chart_id"
    t.index ["target_date"], name: "index_update_runs_on_target_date", unique: true
  end

  add_foreign_key "songs", "charts"
  add_foreign_key "update_items", "songs"
  add_foreign_key "update_items", "update_runs"
  add_foreign_key "update_runs", "charts"
end
