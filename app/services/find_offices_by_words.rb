class FindOfficesByWords
  def call(words_query:, limit: 10)
    # Get all the local authorities with that word/s in the name
    local_authorities = InternalLocalAuthority.where('name ILIKE :query', query: "%#{words_query}%")
    # Find all related offices
    # offices = InternalOffice.where(local_authority__c: [local_authorities.pluck(:local_authority_foreign_key)])

    sql = "
      SELECT offices.*
      FROM internal_offices AS offices
      WHERE recordtypeid = '0124K0000000qqTQAQ'
      AND closed__c = 'false'
      AND name ILIKE '%#{words_query}%'
      OR local_authority__c = '#{local_authorities.pluck(:local_authority_foreign_key)}'
      LIMIT 10
    "

    #
    results = ActiveRecord::Base.connection.execute(sql)
    puts results.count
    {local_authority: nil, offices: results}
  end
end
