import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Extract
datasource0 = glueContext.create_dynamic_frame.from_catalog(database = "offices", table_name = "raw", transformation_ctx = "datasource0")

# Transform
applymapping1 = ApplyMapping.apply(frame = datasource0, mappings = [("id", "string", "id", "string"), ("local_authority__c", "string", "local_authority__c", "string"), ("membership_number__c", "string", "membership_number__c", "string"), ("name", "string", "name", "string"), ("parentid", "string", "parentid", "string"), ("billingstreet", "string", "billingstreet", "string"), ("billingstate", "string", "billingstate", "string"), ("billingcity", "string", "billingcity", "string"), ("billingpostalcode", "string", "billingpostalcode", "string"), ("billinglatitude", "double", "billinglatitude", "double"), ("billinglongitude", "string", "billinglongitude", "string"), ("website", "string", "website", "string"), ("phone", "string", "phone", "string"), ("about_our_advice_service__c", "string", "about_our_advice_service__c", "string"), ("email__c", "string", "email__c", "string"), ("access_details__c", "string", "access_details__c", "string"), ("local_office_opening_hours_information__c", "string", "local_office_opening_hours_information__c", "string"), ("telephone_advice_hours_information__c", "string", "telephone_advice_hours_information__c", "string"), ("closed__c", "boolean", "closed__c", "boolean"), ("lastmodifieddate", "string", "lastmodifieddate", "string"), ("recordtypeid", "string", "recordtypeid", "string")], transformation_ctx = "applymapping1")

# Load data into Parquet
CoalescedMapping_node = applymapping1.coalesce(1)
S3bucket_node3 = glueContext.write_dynamic_frame.from_options(
    frame=CoalescedMapping_node,
    connection_type="s3",
    format="glueparquet",
    connection_options={
        "path": "s3://caew-find-lca-test/offices/parquet/",
        "partitionKeys": [],
    },
    format_options={"compression": "snappy"},
    transformation_ctx="S3bucket_node3",
)

# Load data into Postgres
resolvechoice2 = ResolveChoice.apply(frame = applymapping1, choice = "make_cols", transformation_ctx = "resolvechoice2")
dropnullfields3 = DropNullFields.apply(frame = resolvechoice2, transformation_ctx = "dropnullfields3")
datasink4 = glueContext.write_dynamic_frame.from_jdbc_conf(frame = dropnullfields3, catalog_connection = "database3", connection_options = {"dbtable": "offices", "database": "locations"}, transformation_ctx = "datasink4")

job.commit()
