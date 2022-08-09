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

ActiveRecord::Schema[7.0].define(version: 2022_07_28_162135) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "internal_geolocations", force: :cascade do |t|
    t.string "geolocation_foreign_key", null: false
    t.string "name"
    t.string "postcode__c", null: false
    t.decimal "geolocation__latitude__s", null: false
    t.decimal "geolocation__longitude__s", null: false
    t.string "local_authority__c", null: false
    t.geography "lonlat", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.index ["lonlat"], name: "index_internal_geolocations_on_lonlat", using: :gist
  end

  create_table "internal_local_authorities", force: :cascade do |t|
    t.string "local_authority_foreign_key", null: false
    t.string "name", null: false
    t.string "billingstreet"
    t.string "billingstate"
    t.string "billingpostalcode"
    t.decimal "billinglatitude", null: false
    t.decimal "billinglongitude", null: false
    t.string "recordtypeid", null: false
    t.geography "lonlat", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.index ["lonlat"], name: "index_internal_local_authorities_on_lonlat", using: :gist
  end

  create_table "internal_offices", force: :cascade do |t|
    t.string "office_foreign_key", null: false
    t.string "local_authority__c", null: false
    t.string "membership_number__c"
    t.string "name", null: false
    t.string "parentid", null: false
    t.string "billingstreet"
    t.string "billingstate"
    t.string "billingcity"
    t.string "billingpostalcode"
    t.decimal "billinglatitude", null: false
    t.decimal "billinglongitude", null: false
    t.string "website"
    t.string "phone"
    t.text "about_our_advice_service__c"
    t.string "email__c"
    t.text "access_details__c"
    t.text "local_office_opening_hours_information__c"
    t.text "telephone_advice_hours_information__c"
    t.boolean "closed__c", null: false
    t.datetime "lastmodifieddate"
    t.string "recordtypeid", null: false
    t.geography "lonlat", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.index ["lonlat"], name: "index_internal_offices_on_lonlat", using: :gist
  end

end
