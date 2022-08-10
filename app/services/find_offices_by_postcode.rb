class FindOfficesByPostcode
  METERS_IN_A_MILE = 1609.34

  def call(postcode:, options:)
    limit = options[:limit] || 50
    within = options[:within] || 10
    eligible_only = options[:eligible_only] || false

    if postcode.full?
      geolocation = InternalGeolocation.find_by(postcode__c: postcode.to_s)
      local_authority = InternalLocalAuthority.find_by(local_authority_foreign_key: geolocation.local_authority__c)
      filters = "
        WHERE recordtypeid = '#{InternalOffice::OFFICE_RECORD_ID}'
      "
      filters << " AND local_authority__c = '#{geolocation.local_authority__c}'" if eligible_only
      filters << "AND (ST_DWithin(lonlat, ST_GeogFromText('#{geolocation.lonlat}'), #{ within.to_i * METERS_IN_A_MILE}))" if within.present?
      limit = "LIMIT #{limit}"

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
    else
      geolocation = OpenStruct.new(geolocation__longitude__s: nil, geolocation__latitude__s: nil)
      local_authorities = InternalLocalAuthority.where('billingpostalcode ILIKE :partial_postcode', partial_postcode: "%#{postcode.to_s}%" )

      sql = InternalOffice
        .select("
          *,
          null as distance_in_meters,
          null as eligible
        ")
        .where(
          recordtypeid: InternalOffice::OFFICE_RECORD_ID,
          local_authority__c: local_authorities.pluck(:local_authority_foreign_key)
        )
        .limit(limit)
        .to_sql
    end

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
