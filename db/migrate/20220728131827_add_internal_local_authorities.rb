class AddInternalLocalAuthorities < ActiveRecord::Migration[7.0]
  def up
    create_table :internal_local_authorities, id: false do |t|
      t.string :id, null: false
      t.string :name, null: false
      t.string :billingstreet
      t.string :billingstate
      t.string :billingpostalcode
      t.decimal :billinglatitude, null: false
      t.decimal :billinglongitute, null: false
      t.string :recordtypeid, null: false
    end
  end

  def down
    drop_table :internal_local_authorities
  end
end
