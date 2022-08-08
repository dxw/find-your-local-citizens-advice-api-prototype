class FindOfficesByWords
  def call(words_query:, options: {})
    limit = options[:limit] || 50

    local_authorities = InternalLocalAuthority.where('name ILIKE :query', query: "%#{words_query}%")

    sql = InternalOffice
        .select("
          *,
          null as eligible
        ")
        .where(recordtypeid: InternalOffice::OFFICE_RECORD_ID)
        .where('name ILIKE :query', query: '%#{words_query}%')
        .or(InternalOffice.where(local_authority__c: local_authorities.pluck(:local_authority_foreign_key)))
        .limit(limit)
        .to_sql

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
