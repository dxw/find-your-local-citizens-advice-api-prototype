# README

These prototypes explore different ways Citizens Advice could surface the data needed to build an office finder.

[For more context on how this work concluded read this doc.](https://docs.google.com/document/d/1qeUYvFeTEVVdWHqOpGzUn3l_XwpCKRROKuOxqXTXCTQ/edit#)

- [README](#readme)
  - [Set up](#set-up)
  - [Internal Postgres backed search](#internal-postgres-backed-search)
    - [Example Geolocation CSV](#example-geolocation-csv)
    - [Example local authority CSV](#example-local-authority-csv)
    - [Example office CSV](#example-office-csv)
    - [Example node CSV](#example-node-csv)
  - [External Postgres backed search](#external-postgres-backed-search)
  - [DynamoDB backed search](#dynamodb-backed-search)

## Set up

```
brew install postgresql
brew install postgis
gem install bundler
bin/rails db:prepare
```

## Internal Postgres backed search

By the end of the discovery this path was the preferred option.

To seed the database you'll need to connect to an AWS account that has the expected files in an S3 bucket.

Add your AWS environment variables to `.env`

```
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_SESSION_TOKEN=
```

Run this Ruby code to pull in the data from AWS and seed the local database:

```ruby
rails c
PullLatestData.new.call
```

You can then visit this URL and change the postcode:

<http://localhost:3000/internal_postgres_search/M350LY>

There are a few query params:

`&limit=10` - Number of offices to return

`&eligible_only=true` - Only return offices for the local authority of the given postcode

`&within=5` - Return offices within this number of miles from the search location

[A frontend was built to consume from this local endpoint.](https://github.com/dxw/find-your-local-citizens-advice-frontend-prototype)

### Example Geolocation CSV

If AWS is not ready, you can put a file of this shape into `./tmp/geolocations/data.csv` and use the script without downloading `PullLatestData.new.call(download: false)`.

```
"geolocation_foreign_key","name","postcode__c","geolocation__latitude__s","geolocation__longitude__s","local_authority__c"
"alphanumeric-id","L-123","M35 0LY","53.5","-2.16","alphanumeric-id"
```

### Example local authority CSV

If AWS is not ready, you can put a file of this shape into `./tmp/local_authorities/data.csv` and use the script without downloading `PullLatestData.new.call(download: false)`.

```
"local_authority_foreign_key","name","billingpostalcode","billinglatitude","billinglongitude","recordtypeid"
"alphanumeric-id","Council name","SL6 1RF","51.52195","-0.71866","alphanumeric-id"
```

### Example office CSV

If AWS is not ready, you can put a file of this shape into `./tmp/offices/data.csv` and use the script without downloading `PullLatestData.new.call(download: false)`.

```
"office_foreign_key","local_authority__c","membership_number__c","name","billingcity","billingpostalcode","billinglatitude","billinglongitude","website","phone","email__c","closed__c","lastmodifieddate","recordtypeid"
"alphanumeric-id","alphanumeric-id","1/0001","Office name","London","SE11 4HQ","51.490293177080964","-0.10689714161145202","www.caml.org.uk","07123456789","email@example.org.uk","false","2022-07-08T12:45:42.000Z","0124K0000000qqTQAQ"
```

### Example node CSV

If AWS is not ready, you can put a file of this shape into `./tmp/nodes/data.csv` and use the script without downloading `PullLatestData.new.call(download: false)`.

"office_foreign_key","account_name","name","record_type","weekday","start_time","end_time","open_time_present","created_date","opening_time_type"
"alphanumeric-id","Aldershot Citizens Advice","N-123","Opening Time","Friday","09:30","15:00","1","27/04/2022","Telephone advice hours"

## External Postgres backed search

Ask for and set the following environment variable in `/.env`:

```
EXTERNAL_DATABASE_URL="postgres://postgres:@x.x.eu-west-2.rds.amazonaws.com/locations"
```

```
bin/rails server
```

Search with postcodes through the URL:
<http://localhost:3000/external_postgres_search/M350LY>

## DynamoDB backed search

A DynamoDB instance needs to be set up and seeded with data. In this prototype AWS Glue wrote directly to DynamoDB with data taken from S3.

Add your AWS environment variables to `.env`

```
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_SESSION_TOKEN=
```

Visit this URL in the browser:

<http://localhost:3000/dynamo_search/PO211LD>

We chose not to pursue the options for location based search that would return results in the order of proximity.
