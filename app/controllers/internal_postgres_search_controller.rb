
class InternalPostgresSearchController < ApplicationController
  def show
    postcode_query = UKPostcode.parse(search_query).to_s
    eligible_only = params[:eligible_only] || "true"
    limit = params[:limit].present? ? params[:limit].to_i : 10

    # TODO: figure out how to protect users from writing back to this database
    geolocation = InternalGeolocation.find_by(postcode__c: postcode_query)
    local_authority = InternalLocalAuthority.find_by(local_authority_foreign_key: geolocation.local_authority__c)
    # TODO: Filter out outreaches once we understand how to interpret the `recordtypeid` column.
    # @offices = InternalOffice.where(local_authority__c: local_authority.id)

    # TODO: Understand how this should work. Limit to 10 or within 10 miles?
    # 16093.44 = meters in 10 miles
    # WHERE (ST_DWithin(lonlat, ST_GeogFromText('#{geolocation.lonlat}'), 16093.44))
    filters = "WHERE recordtypeid = '0124K0000000qqTQAQ'"
    filters << " AND local_authority__c = '#{geolocation.local_authority__c}'" if eligible_only == "true"
    limit = "LIMIT #{limit}"

    sql = "
      SELECT offices.*, ST_Distance(offices.lonlat,ST_GeogFromText('#{geolocation.lonlat}')) as distance_in_meters
      FROM internal_offices AS offices
      #{filters}
      ORDER BY lonlat <-> ST_GeogFromText('#{geolocation.lonlat}')
      #{limit}
    "

    results = ActiveRecord::Base.connection.execute(sql)
    render json: {
      local_authority: local_authority,
      offices: results
    }
  end

  def search_query
    params.require(:id)
  end
end
