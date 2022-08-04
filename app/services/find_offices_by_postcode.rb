class FindOfficesByPostcode
  def call(postcode_query:, limit: 10, within: nil, eligible_only: true)
    # TODO: figure out how to protect users from writing back to this database
    geolocation = InternalGeolocation.find_by(postcode__c: postcode_query)
    local_authority = InternalLocalAuthority.find_by(local_authority_foreign_key: geolocation.local_authority__c)
    # TODO: Filter out outreaches once we understand how to interpret the `recordtypeid` column.
    # @offices = InternalOffice.where(local_authority__c: local_authority.id)
    filters = "
      WHERE recordtypeid = '0124K0000000qqTQAQ'
    "
    filters << " AND local_authority__c = '#{geolocation.local_authority__c}'" if eligible_only
    filters << "AND (ST_DWithin(lonlat, ST_GeogFromText('#{geolocation.lonlat}'), #{ within.to_i *  1609.34}))" if within.present?
    limit = limit.present? ? "LIMIT #{limit}" : "LIMIT 10"

    sql = "
      SELECT
        offices.*,
        ST_Distance(offices.lonlat,ST_GeogFromText('#{geolocation.lonlat}')) as distance_in_meters,
        local_authority__c = '#{geolocation.local_authority__c}' as eligible
      FROM internal_offices AS offices
      #{filters}
      ORDER BY lonlat <-> ST_GeogFromText('#{geolocation.lonlat}')
      #{limit}
    "

    results = ActiveRecord::Base.connection.execute(sql)

    {
      location: {
        longitude: geolocation.geolocation__longitude__s,
        latitude: geolocation.geolocation__latitude__s,
      },
      local_authority: local_authority,
      offices: results
    }
  end
end
