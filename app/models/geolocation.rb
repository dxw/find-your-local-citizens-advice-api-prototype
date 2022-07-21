class Geolocation < ActiveRecord::Base
  establish_connection :external_database
  table_name = "geolocations"
end
