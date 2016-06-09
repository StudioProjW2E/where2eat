# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160406080801) do

  create_table "Rates", primary_key: "RateID", force: :cascade do |t|
    t.integer  "UserID",       limit: 4,     null: false
    t.integer  "RestaurantID", limit: 4,     null: false
    t.integer  "Rate",         limit: 4,     null: false
    t.text     "Comment",      limit: 65535, null: false
    t.datetime "timestamp",                  null: false
  end

  create_table "Restaurants", primary_key: "RestaurantID", force: :cascade do |t|
    t.string "Name",        limit: 50,  null: false
    t.string "Description", limit: 200, null: false
    t.string "Address",     limit: 50,  null: false
    t.string "Link",        limit: 100, null: false
    t.float  "Latitude",    limit: 53,  null: false
    t.float  "Longitude",   limit: 53,  null: false
  end

  add_index "Restaurants", ["Name", "Address", "Link", "Latitude", "Longitude"], name: "Name", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "provider",         limit: 255
    t.string   "uid",              limit: 255
    t.string   "name",             limit: 255
    t.string   "oauth_token",      limit: 255
    t.datetime "oauth_expires_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

end
