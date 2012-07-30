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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120728202924) do

  create_table "sessions", :force => true do |t|
    t.string    "username"
    t.timestamp "last_seen_at"
    t.timestamp "created_at",   :null => false
    t.timestamp "updated_at",   :null => false
  end

  create_table "users", :force => true do |t|
    t.string    "untappd_username"
    t.timestamp "last_seen_at"
    t.string    "foursquare_token"
    t.timestamp "created_at",       :null => false
    t.timestamp "updated_at",       :null => false
  end

end
