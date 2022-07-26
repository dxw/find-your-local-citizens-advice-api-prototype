
class InternalPostgresSearchController < ApplicationController
  def show
    postcode = UKPostcode.parse(search_query)
    if UKPostcode.parse(search_query).valid?
      result = FindOfficesByPostcode.new.call(
        postcode: postcode,
        options: {
          limit: params.fetch(:limit, nil),
          eligible_only: !!params[:eligible_only],
          within: params.fetch(:within, nil)
        }
      )
    else
      result = FindOfficesByWords.new.call(
        words_query: search_query,
        options: {
          limit: params.fetch(:limit, nil)
        }
      )
    end

    location = result.fetch(:location, nil)
    local_authority = result.fetch(:local_authority, nil)
    offices = result.fetch(:offices, [])

    render json: {
      location: location,
      results: {
        local_authority: local_authority,
        offices: offices
      }
    }
  end

  def search_query
    params.require(:id)
  end
end
