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

ActiveRecord::Schema[8.0].define(version: 2026_01_10_134416) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  add_foreign_key "songs", "charts"
end
