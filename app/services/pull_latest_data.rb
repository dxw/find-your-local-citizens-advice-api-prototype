require "aws-sdk-s3"

class PullLatestData
  def s3
    @s3 ||= Aws::S3::Client.new(region: 'eu-west-2')
  end

  def call(download: true)
    if download
      FileUtils.mkdir_p('tmp/geolocations')
      FileUtils.rm('tmp/geolocations/data.csv', :force => true)
      File.open("tmp/geolocations/data.csv", 'wb') do |file|
        reap = s3.get_object({ bucket:'caew-find-lca-test', key: "geolocations/csv/renamed/data.csv" }, target: "tmp/geolocations/data.csv")
      end

      FileUtils.mkdir_p('tmp/local_authorities')
      FileUtils.rm('tmp/local_authorities/data.csv', :force => true)
      File.open("tmp/local_authorities/data.csv", 'wb') do |file|
        reap = s3.get_object({ bucket:'caew-find-lca-test', key: "local-authorities/csv/renamed/data.csv" }, target: "tmp/local_authorities/data.csv")
      end

      # This CSV needs cleaning. It has 5 rows without long and lats:
      # 2385, 1548, 1419, 1358, 853, 459
      # These need to be removed for now, data cleaning can be dealt with later.
      FileUtils.mkdir_p('tmp/offices')
      FileUtils.rm('tmp/offices/data.csv', :force => true)
      File.open("tmp/offices/data.csv", 'wb') do |file|
        reap = s3.get_object({ bucket:'caew-find-lca-test', key: "offices/csv/renamed/data.csv" }, target: "tmp/offices/data.csv")
      end
    end

    # df = Pandas.read_parquet('./tmp/local_authorities/parquet/data.parquet')
    # binding.pry
    # df.to_sql("internal_local_authorities", ActiveRecord::Base.connection)
    # PyCall::PyError: <class 'AttributeError'>: 'PyCall.ruby_object' object has no attribute 'cursor'

    InternalGeolocation.transaction do
      InternalGeolocation.delete_all
      # TODO: Figure out how to give it a relative path to tmp/
      sql = "
        COPY internal_geolocations(geolocation_foreign_key, name, postcode__c, geolocation__latitude__s, geolocation__longitude__s, local_authority__c)
        FROM '/Users/tomhipkin/sites/citizens-advice/find-your-local-citizens-advice-prototype/tmp/geolocations/data.csv'
        DELIMITER ','
        CSV HEADER;
      "
      ActiveRecord::Base.connection.execute(sql)

      # INFO: This takes a long time, 1 minute and 4 seconds with and 19 seconds without.
      # Should/can the downloaded CSV take care of this?
      sql = "UPDATE internal_geolocations SET lonlat = ST_SETSRID(ST_MakePoint(geolocation__longitude__s, geolocation__latitude__s),4326);"
      ActiveRecord::Base.connection.execute(sql)
    end

    InternalLocalAuthority.transaction do
      InternalLocalAuthority.delete_all
      # TODO: Figure out how to give it a relative path to tmp/
      sql = "
        COPY internal_local_authorities(local_authority_foreign_key, name, billingpostalcode, billinglatitude, billinglongitude, recordtypeid)
        FROM '/Users/tomhipkin/sites/citizens-advice/find-your-local-citizens-advice-prototype/tmp/local_authorities/data.csv'
        DELIMITER ','
        CSV HEADER;
      "
      ActiveRecord::Base.connection.execute(sql)

      sql = "UPDATE internal_local_authorities SET lonlat = ST_SETSRID(ST_MakePoint(billinglongitude, billinglatitude),4326);"
      ActiveRecord::Base.connection.execute(sql)
    end

    InternalOffice.transaction do
      InternalOffice.delete_all
      # TODO: Figure out how to give it a relative path to tmp/
      sql = "
        COPY internal_offices(office_foreign_key, local_authority__c, membership_number__c, name, billingstate, billingcity, billingpostalcode, billinglatitude, billinglongitude, website, phone, email__c, access_details__c, closed__c, lastmodifieddate, recordtypeid)
        FROM '/Users/tomhipkin/sites/citizens-advice/find-your-local-citizens-advice-prototype/tmp/offices/data.csv'
        DELIMITER ','
        CSV HEADER;
      "
      ActiveRecord::Base.connection.execute(sql)

      sql = "UPDATE internal_offices SET lonlat = ST_SETSRID(ST_MakePoint(billinglongitude, billinglatitude),4326);"
      ActiveRecord::Base.connection.execute(sql)
    end

    InternalOffice.count
  end
end
