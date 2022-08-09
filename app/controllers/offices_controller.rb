class OfficesController < ApplicationController
  def show
    id = params[:id]
    @office = InternalOffice.find(id)

    # Order the opening times by day of the week
    sql = Arel.sql("
      CASE weekday
      WHEN 'Monday'
      THEN 1
      WHEN 'Tuesday'
      THEN 2
      WHEN 'Wednesday'
      THEN 3
      WHEN 'Thursday'
      THEN 4
      WHEN 'Friday'
      THEN 5
      WHEN 'Saturday'
      THEN 6
      WHEN 'Sunday'
      THEN 7
      END
    ")

    # INFO: Nodes are the Salesforce resource name and can include a variety
    # of information such as open/close times and available services.
    nodes = InternalNode
      .where(office_foreign_key: @office.office_foreign_key)
      .where(opening_time_type: ["Local office opening hours", "Telephone advice hours"])
      .order(sql)

    grouped_nodes = nodes.group_by(&:opening_time_type)

    @office_opening_times = grouped_nodes["Local office opening hours"]
    @telephone_advice_times = grouped_nodes["Telephone advice hours"]

    render 'offices/show', formats: :json, handlers: :jbuilder
  end
end
