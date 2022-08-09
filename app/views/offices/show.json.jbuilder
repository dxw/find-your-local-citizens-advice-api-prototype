json.office do
  json.office_foreign_key @office.office_foreign_key
  json.local_authority__c @office.local_authority__c
  json.membership_number__c @office.membership_number__c
  json.name @office.name
  json.parentid @office.parentid
  json.billingstreet @office.billingstreet
  json.billingstate @office.billingstate
  json.billingcity @office.billingcity
  json.billingpostalcode @office.billingpostalcode
  json.billinglatitude @office.billinglatitude
  json.billinglongitude @office.billinglongitude
  json.website @office.website
  json.phone @office.phone
  json.about_our_advice_service__c @office.about_our_advice_service__c
  json.email__c @office.email__c
  json.access_details__c @office.access_details__c
  json.local_office_opening_hours_information__c @office.local_office_opening_hours_information__c
  json.telephone_advice_hours_information__c @office.telephone_advice_hours_information__c
  json.closed__c @office.closed__c
  json.lastmodifieddate @office.lastmodifieddate
  json.recordtypeid @office.recordtypeid

  json.office_opening_times @office_opening_times do |node|
    json.partial! partial: 'offices/node', node: node
  end

  json.telephone_advice_times @telephone_advice_times do |node|
    json.partial! partial: 'offices/node', node: node
  end
end
