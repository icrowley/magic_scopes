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

ActiveRecord::Schema.define(:version => 20121020094329) do

  create_table "comments", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "user_id"
    t.integer  "next_id"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.string   "state"
    t.string   "likes_state"
    t.float    "rating"
    t.integer  "likes_num"
    t.boolean  "featured"
    t.boolean  "hidden"
    t.boolean  "best"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "age"
    t.integer  "weight"
    t.integer  "height"
    t.text     "about"
    t.integer  "parent_id"
    t.integer  "specable_id"
    t.string   "specable_type"
    t.string   "state"
    t.decimal  "dec",            :precision => 10, :scale => 2
    t.float    "rating"
    t.float    "floato"
    t.float    "floatum"
    t.boolean  "admin"
    t.boolean  "moderator"
    t.date     "created_at"
    t.datetime "updated_at"
    t.datetime "last_logged_at"
  end

end
