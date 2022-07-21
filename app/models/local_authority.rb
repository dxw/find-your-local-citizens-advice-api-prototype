class LocalAuthority < ActiveRecord::Base
  establish_connection :external_database
  table_name = "local_authorities"
end
