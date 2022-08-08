import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node S3 bucket
S3bucket_node1 = glueContext.create_dynamic_frame.from_options(
    format_options={
        "quoteChar": '"',
        "escaper": "",
        "withHeader": True,
        "separator": ",",
        "optimizePerformance": False,
    },
    connection_type="s3",
    format="csv",
    connection_options={
        "paths": ["s3://caew-find-lca-test/offices/raw/"],
        "recurse": True,
    },
    transformation_ctx="S3bucket_node1",
)

# Script generated for node ApplyMapping
ApplyMapping_node2 = ApplyMapping.apply(
    frame=S3bucket_node1,
    mappings=[
        ("Id", "string", "office_foreign_key", "string"),
        ("Local_Authority__c", "string", "local_authority__c", "string"),
        ("Membership_Number__c", "string", "membership_number__c", "string"),
        ("Name", "string", "name", "string"),
        # ("BillingStreet", "string", "billingstreet", "string"),
        # ("BillingState", "string", "billingstate", "string"),
        ("BillingCity", "string", "billingcity", "string"),
        ("BillingPostalCode", "string", "billingpostalcode", "string"),
        ("BillingLatitude", "string", "billinglatitude", "string"),
        ("BillingLongitude", "string", "billinglongitude", "string"),
        ("Website", "string", "website", "string"),
        ("Phone", "string", "phone", "string"),
        ("Email__c", "string", "email__c", "string"),
        # ("Access_details__c", "string", "access_details__c", "string"),
        # ("Local_Office_Opening_Hours_Information__c", "string", "local_office_opening_hours_information__c", "null"),
        # ("Telephone_Advice_Hours_Information__c", "string", "telephone_advice_hours_information__c", "null"),
        ("Closed__c", "string", "closed__c", "string"),
        ("LastModifiedDate", "string", "lastmodifieddate", "string"),
        ("RecordTypeId", "string", "recordtypeid", "string"),
    ],
    transformation_ctx="ApplyMapping_node2",
)

# Combine any output into a single file
ApplyMapping_node2 = ApplyMapping_node2.coalesce(1)

# Script generated for node S3 bucket
## Insert into the Data catalog. DynamicFrame doesn't support overwrites but this action
## should ensure it matches the schema.
S3bucket_node3 = glueContext.getSink(
    path="s3://caew-find-lca-test/offices/csv/versions/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=[],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="salesforce_data", catalogTableName="offices"
)
S3bucket_node3.setFormat("csv")
S3bucket_node3.writeFrame(ApplyMapping_node2)

## Write the final file with overwrite to ensure one file remains for the API
df = ApplyMapping_node2.toDF()
df.write.mode('overwrite').csv('s3://caew-find-lca-test/offices/csv/processed/', header=True, quoteAll=True, escape="\\")

# Copy the file across to a stable filename
import boto3
bucketname = "caew-find-lca-test"
s3 = boto3.resource('s3')
my_bucket = s3.Bucket(bucketname)
source = "offices/csv/processed/"
target = "offices/csv/renamed"
for obj in my_bucket.objects.filter(Prefix=source):
    source_filename = (obj.key).split('/')[-1]
    copy_source = {
        'Bucket': bucketname,
        'Key': obj.key
    }
    target_filename = "{}/{}".format(target, "data.csv")
    s3.meta.client.copy(copy_source, bucketname, target_filename)

job.commit()
