class AddInternalGeolocations < ActiveRecord::Migration[7.0]
  def up
    create_table :internal_geolocations, id: false do |t|
      t.string :id, null: false
      t.string :name
      t.string :postcode__c, null: false
      t.decimal :geolocation__latitude__s, null: false
      t.decimal :geolocation__longitude__s, null: false
      t.string :local_authority__c, null: false

      # SQL COPY from CSV fails as it doesn't have these columns
      # t.timestamps
    end
  end

  def down
    drop_table :internal_geolocations
  end
end
