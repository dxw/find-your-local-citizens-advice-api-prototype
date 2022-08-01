class AddInternalGeolocations < ActiveRecord::Migration[7.0]
  def up
    create_table :internal_geolocations do |t|
      t.string :geolocation_foreign_key, null: false
      t.string :name
      t.string :postcode__c, null: false
      t.decimal :geolocation__latitude__s, null: false
      t.decimal :geolocation__longitude__s, null: false
      t.string :local_authority__c, null: false

      t.st_point :lonlat, geographic: true
      t.index :lonlat, using: :gist
      # SQL COPY from CSV fails as it doesn't have these columns
      # t.timestamps
    end
  end

  def down
    drop_table :internal_geolocations
  end
end
