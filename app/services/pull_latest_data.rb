require "aws-sdk-s3"

class PullLatestData
  def s3
    @s3 ||= Aws::S3::Client.new(region: 'eu-west-2')
  end

  def call(
    download: true,
    skip_geolocations: false,
    skip_local_authorities: false,
    skip_offices: false,
    skip_nodes: false)
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

      FileUtils.mkdir_p('tmp/offices')
      FileUtils.rm('tmp/offices/data.csv', :force => true)
      File.open("tmp/offices/data.csv", 'wb') do |file|
        reap = s3.get_object({ bucket:'caew-find-lca-test', key: "offices/csv/renamed/data.csv" }, target: "tmp/offices/data.csv")
      end

      FileUtils.mkdir_p('tmp/nodes')
      FileUtils.rm('tmp/nodes/data.csv', :force => true)
      File.open("tmp/nodes/data.csv", 'wb') do |file|
        reap = s3.get_object({ bucket:'caew-find-lca-test', key: "nodes/csv/renamed/data.csv" }, target: "tmp/nodes/data.csv")
      end
    end

    # Offices has a lot of bad data, remove rows with missing values
    clean_office_data

    load_geolocations unless skip_geolocations
    load_local_authorities unless skip_local_authorities
    load_offices unless skip_offices
    load_nodes unless skip_nodes

    [
      geolocations: InternalGeolocation.count,
      local_authorities: InternalLocalAuthority.count,
      offices: InternalOffice.count,
      nodes: InternalNode.count
    ]
  end

  def load_geolocations
    InternalGeolocation.transaction do
      InternalGeolocation.delete_all
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
  end

  def load_local_authorities
    InternalLocalAuthority.transaction do
      InternalLocalAuthority.delete_all
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
  end

  def load_offices
    InternalOffice.transaction do
      InternalOffice.delete_all
      sql = "
        COPY internal_offices(office_foreign_key, local_authority__c, membership_number__c, name, parentid, billingstreet, billingstate, billingcity, billingpostalcode, billinglatitude, billinglongitude, website, phone, email__c, access_details__c, about_our_advice_service__c, local_office_opening_hours_information__c, telephone_advice_hours_information__c, closed__c, lastmodifieddate, recordtypeid)
        FROM '/Users/tomhipkin/sites/citizens-advice/find-your-local-citizens-advice-prototype/tmp/offices/cleaned_data.csv'
        DELIMITER ','
        CSV HEADER;
      "
      ActiveRecord::Base.connection.execute(sql)

      sql = "UPDATE internal_offices SET lonlat = ST_SETSRID(ST_MakePoint(billinglongitude, billinglatitude),4326);"
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def load_nodes
    InternalNode.transaction do
      InternalNode.delete_all
      sql = "
        COPY internal_nodes(office_foreign_key, account_name, name, record_type, weekday, start_time, end_time, open_time_present, created_date, opening_time_type)
        FROM '/Users/tomhipkin/sites/citizens-advice/find-your-local-citizens-advice-prototype/tmp/nodes/data.csv'
        DELIMITER ','
        CSV HEADER;
      "
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def clean_office_data
    require 'csv'

    rows = []
    headers = nil

    office_rows = CSV.foreach('tmp/offices/data.csv', headers: true, liberal_parsing: true).with_index(2) do |row, ln|
      headers ||= row.headers

      # Office data includes some rows without these essential values
      next if row["local_authority__c"].blank? ||
      row["billinglatitude"].blank? ||
      row["billinglongitude"].blank? ||
      row["closed__c"].blank?

      rows << row
    end

    FileUtils.rm('tmp/offices/cleaned_data.csv', :force => true)

    CSV.open("tmp/offices/cleaned_data.csv", "w", liberal_parsing: true) do |csv|
      csv << headers
      rows.each do |office|
        csv << office
      end
    end
  end
end
