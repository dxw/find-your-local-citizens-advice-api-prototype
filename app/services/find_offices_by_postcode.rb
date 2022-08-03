class FindOfficesByPostcode
  def call(postcode_query:, limit: 10, eligible_only: true)
    # TODO: figure out how to protect users from writing back to this database
    geolocation = InternalGeolocation.find_by(postcode__c: postcode_query)
    local_authority = InternalLocalAuthority.find_by(local_authority_foreign_key: geolocation.local_authority__c)
    # TODO: Filter out outreaches once we understand how to interpret the `recordtypeid` column.
    # @offices = InternalOffice.where(local_authority__c: local_authority.id)

    # TODO: Understand how this should work. Limit to 10 or within 10 miles?
    # 16093.44 = meters in 10 miles
    # WHERE (ST_DWithin(lonlat, ST_GeogFromText('#{geolocation.lonlat}'), 16093.44))
    filters = "
      WHERE recordtypeid = '0124K0000000qqTQAQ'
      AND closed__c = 'false'
    "
    filters << " AND local_authority__c = '#{geolocation.local_authority__c}'" if eligible_only

    limit = limit.present? ? "LIMIT #{limit}" : "LIMIT 10"

    sql = "
      SELECT offices.*, ST_Distance(offices.lonlat,ST_GeogFromText('#{geolocation.lonlat}')) as distance_in_meters
      FROM internal_offices AS offices
      #{filters}
      ORDER BY lonlat <-> ST_GeogFromText('#{geolocation.lonlat}')
      #{limit}
    "

    results = ActiveRecord::Base.connection.execute(sql)

    {local_authority: local_authority, offices: results}
  end
end
