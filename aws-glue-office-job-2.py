import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Extras
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as F

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node Data Catalog table
DataCatalogtable_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="offices", table_name="raw", transformation_ctx="DataCatalogtable_node1"
)

# Script generated for node ApplyMapping
ApplyMapping_node2 = ApplyMapping.apply(
    frame=DataCatalogtable_node1,
    mappings=[("id", "string", "id", "string"), ("local_authority__c", "string", "local_authority__c", "string"), ("membership_number__c", "string", "membership_number__c", "string"), ("name", "string", "name", "string"), ("parentid", "string", "parentid", "string"), ("billingstreet", "string", "billingstreet", "string"), ("billingstate", "string", "billingstate", "string"), ("billingcity", "string", "billingcity", "string"), ("billingpostalcode", "string", "billingpostalcode", "string"), ("billinglatitude", "double", "billinglatitude", "double"), ("billinglongitude", "string", "billinglongitude", "string"), ("website", "string", "website", "string"), ("phone", "string", "phone", "string"), ("about_our_advice_service__c", "string", "about_our_advice_service__c", "string"), ("email__c", "string", "email__c", "string"), ("access_details__c", "string", "access_details__c", "string"), ("local_office_opening_hours_information__c", "string", "local_office_opening_hours_information__c", "string"), ("telephone_advice_hours_information__c", "string", "telephone_advice_hours_information__c", "string"), ("closed__c", "boolean", "closed__c", "boolean"), ("lastmodifieddate", "string", "lastmodifieddate", "string"), ("recordtypeid", "string", "recordtypeid", "string")],
    transformation_ctx="ApplyMapping_node2",
)

# Load data into Parquet
spark.conf.set('spark.sql.sources.partitionOverwriteMode','dynamic')
df = ApplyMapping_node2.toDF()
df = df.coalesce(1)
df.write.mode('overwrite').parquet('s3://caew-find-lca-test/offices/parquet/')

# Copy the file across to a stable filename
import boto3
bucketname = "caew-find-lca-test"
s3 = boto3.resource('s3')
my_bucket = s3.Bucket(bucketname)
source = "offices/parquet/"
target = "offices/parquet/renamed"

for obj in my_bucket.objects.filter(Prefix=source):
    source_filename = (obj.key).split('/')[-1]
    copy_source = {
        'Bucket': bucketname,
        'Key': obj.key
    }
    target_filename = "{}/{}".format(target, "data.parquet")
    s3.meta.client.copy(copy_source, bucketname, target_filename)

# Load data into Postgres
resolvechoice2 = ResolveChoice.apply(frame = ApplyMapping_node2, choice = "make_cols", transformation_ctx = "resolvechoice2")
dropnullfields3 = DropNullFields.apply(frame = resolvechoice2, transformation_ctx = "dropnullfields3")
datasink4 = glueContext.write_dynamic_frame.from_jdbc_conf(frame = dropnullfields3, catalog_connection = "database3", connection_options = {"dbtable": "offices", "database": "locations"}, transformation_ctx = "datasink4")


# Load data into Dynamodb
from pyspark.sql.functions import when, col

# Convert any cell in column `local_authority__c` with a blank string to a null value
# Drop all rows with null values for `local_authority__c`
custom_df = ApplyMapping_node2.toDF()
custom_df2 = custom_df.select([when(col(c)=="",None).otherwise(col(c)).alias(c) for c in custom_df.columns])
custom_df3 = custom_df2.dropna(subset=['local_authority__c'])
custom_df4 = DynamicFrame.fromDF(custom_df, glueContext, 'tmp_offices')


glueContext.write_dynamic_frame_from_options (
    frame = custom_df4,
    connection_type = "dynamodb",
    connection_options  = { "dynamodb.region": "eu-west-2",
                            "dynamodb.output.tableName": "offices",
                            "dynamodb.throughput.write.percent": "1.0" }
  )

job.commit()
