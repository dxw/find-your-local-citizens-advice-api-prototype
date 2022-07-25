
class DynamoSearchController < ApplicationController
  def show

    postcode_query = UKPostcode.parse(search_query).to_s

    @dynamo_client ||= Aws::DynamoDB::Client.new

    geolocation_query_condition = {
      table_name: "geolocations",
      index_name: "postcode__c-index",
      key_condition_expression: '#postcode__c = :postcode__c',
      expression_attribute_names: {
        '#postcode__c' => 'postcode__c',
      },
      expression_attribute_values: {
        ':postcode__c' => postcode_query
      }
    }
    geolocation_result = @dynamo_client.query(geolocation_query_condition)
    local_authority_id = geolocation_result.items.first.fetch("local_authority__c")

    # Since we have the local authority ID from geolocations, it's not
    # yet clear what data we need from this query.
    local_authority_query_condition = {
      table_name: "local_authorities",
      key_condition_expression: '#id = :id',
      expression_attribute_names: {
        '#id' => 'id',
      },
      expression_attribute_values: {
        ':id' => local_authority_id
      }
    }
    local_authority_result = @dynamo_client.query(local_authority_query_condition)

    office_query_condition = {
      table_name: "offices",
      index_name: "local_authority__c-index",
      key_condition_expression: '#local_authority__c = :local_authority__c',
      expression_attribute_names: {
        '#local_authority__c' => 'local_authority__c',
      },
      expression_attribute_values: {
        ':local_authority__c' => local_authority_id
      }
    }
    office_result = @dynamo_client.query(office_query_condition)

    render json: office_result.items
  end

  def search_query
    params.require(:id)
  end
end
