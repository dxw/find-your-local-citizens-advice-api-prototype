class AddInternalLocalAuthorities < ActiveRecord::Migration[7.0]
  def up
    create_table :internal_local_authorities do |t|
      t.string :local_authority_foreign_key, null: false
      t.string :name, null: false
      t.string :billingstreet
      t.string :billingstate
      t.string :billingpostalcode
      t.decimal :billinglatitude, null: false
      t.decimal :billinglongitude, null: false
      t.string :recordtypeid, null: false

      t.st_point :lonlat, geographic: true
      t.index :lonlat, using: :gist
    end
  end

  def down
    drop_table :internal_local_authorities
  end
end
