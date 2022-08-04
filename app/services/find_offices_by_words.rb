class FindOfficesByWords
  def call(words_query:, limit: 10)
    # Get all the local authorities with that word/s in the name
    local_authorities = InternalLocalAuthority.where('name ILIKE :query', query: "%#{words_query}%")
    # Find all related offices
    # offices = InternalOffice.where(local_authority__c: [local_authorities.pluck(:local_authority_foreign_key)])

    sql = "
      SELECT
        offices.*,
        null as eligible
      FROM internal_offices AS offices
      WHERE recordtypeid = '#{InternalOffice::OFFICE_RECORD_ID}'
      AND closed__c = 'false'
      AND name ILIKE '%#{words_query}%'
      OR local_authority__c = '#{local_authorities.pluck(:local_authority_foreign_key)}'
      LIMIT 10
    "

    results = ActiveRecord::Base.connection.execute(sql)

    {
      location: {
        longitude: nil,
        latitude: nil,
      },
      local_authority: nil,
      offices: results
    }
  end
end
