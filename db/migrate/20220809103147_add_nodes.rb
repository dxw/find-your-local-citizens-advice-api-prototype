class AddNodes < ActiveRecord::Migration[7.0]
  def up
    create_table :internal_nodes do |t|
      t.string :office_foreign_key, null: false
      t.string :account_name
      t.string :name
      t.string :record_type, null: false
      t.string :weekday
      t.string :start_time
      t.string :end_time
      t.string :open_time_present
      t.string :created_date
      t.string :opening_time_type

      t.index :office_foreign_key
      t.index :record_type
    end
  end

  def down
    drop_table :internal_nodes
  end
end
