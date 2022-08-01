
class InternalPostgresSearchController < ApplicationController
  def show
    postcode_query = UKPostcode.parse(search_query).to_s

    # TODO: figure out how to protect users from writing back to this database
    geolocation = InternalGeolocation.find_by(postcode__c: postcode_query)
    local_authority = InternalLocalAuthority.find_by(id: geolocation.local_authority__c)
    # TODO: Filter out outreaches once we understand how to interpret the `recordtypeid` column.
    # @offices = InternalOffice.where(local_authority__c: local_authority.id)

    sql = "
      SELECT * FROM internal_offices
      WHERE recordtypeid = '0124K0000000qqTQAQ'
      ORDER BY lonlat <-> ST_GeogFromText('#{geolocation.lonlat}')
      LIMIT 10
    "

    results = ActiveRecord::Base.connection.execute(sql)

    render json: results.to_json
  end

  def search_query
    params.require(:id)
  end
end
