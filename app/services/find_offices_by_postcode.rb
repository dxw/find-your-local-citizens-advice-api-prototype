class FindOfficesByPostcode
  def call(postcode:, limit: 10, within: nil, eligible_only: true)
    if postcode.full?
      geolocation = InternalGeolocation.find_by(postcode__c: postcode.to_s)
      local_authority = InternalLocalAuthority.find_by(local_authority_foreign_key: geolocation.local_authority__c)
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
          recordtypeid: "0124K0000000qqTQAQ",
          local_authority__c: local_authorities.pluck(:local_authority_foreign_key)
        )
        .limit(limit.present? ? limit : 10)
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
