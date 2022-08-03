class OfficesController < ApplicationController
  def show
    id = params[:id]
    result = InternalOffice.find(id)
    render json: result.to_json
  end
end
