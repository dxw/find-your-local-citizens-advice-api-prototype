
class InternalPostgresSearchController < ApplicationController
  def show
    if UKPostcode.parse(search_query).valid?
      postcode_query = UKPostcode.parse(search_query).to_s

      result = FindOfficesByPostcode.new.call(
        postcode_query: postcode_query,
        limit: params.fetch(:limit, nil),
        eligible_only: !!params[:eligible_only]
      )

      local_authority = result.fetch(:local_authority, nil)
      offices = result.fetch(:offices, [])

      render json: {
        local_authority: local_authority,
        offices: offices
      }
    else
      result = FindOfficesByWords.new.call(
        words_query: search_query,
        limit: params.fetch(:limit, nil)
      )

      local_authority = result.fetch(:local_authority, nil)
      offices = result.fetch(:offices, [])

      render json: {
        local_authority: nil,
        offices: offices
      }
    end
  end

  def search_query
    params.require(:id)
  end
end
