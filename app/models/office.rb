class Office < ActiveRecord::Base
  establish_connection :external_database
  # connects_to database: { reading: :external_database }
  table_name = "offices"
end
