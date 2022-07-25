class PostgresSearchController < ApplicationController
  def show
    postcode_query = "#{search_query.slice(0..2)} #{search_query.slice(3..6)}".upcase

    # TODO: figure out how to protect users from writing back to this database
    geolocation = Geolocation.find_by(postcode__c: postcode_query)
    local_authority = LocalAuthority.find_by(id: geolocation.local_authority__c)
    # TODO: Filter out outreaches once we understand how to interpret the `recordtypeid` column.
    @offices = Office.where(local_authority__c: local_authority.id)
    render json: @offices.to_json
  end

  def search_query
    params.require(:id)
  end
end
