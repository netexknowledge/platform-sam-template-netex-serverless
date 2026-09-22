# AWS GLUE python script that extract data from RDS mysql table and save in csv format in S3 bucket

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 's3_target_path', 'list_connection_name'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

connection_name = args["list_connection_name"].split(',')[0]
tbl_name = 'tasks'
s3_bucket = args["s3_target_path"]

# S3 location for output
s3_output = s3_bucket+"glue-testing-mysql/tasks"

# Read data from AWS Glue connection
dynamic_frame_read = glueContext.create_dynamic_frame.from_options(
    connection_type="mysql", 
    connection_options={
        "useConnectionProperties": "true",
        "connectionName": connection_name,
        "dbtable": tbl_name
    }
)

# Convert dynamic frame to data frame to use standard pyspark functions
data_frame = dynamic_frame_read.toDF()

# Coalesce the data frame to a single partition
data_frame = data_frame.coalesce(1)

# Write data back to S3 in CSV format
data_frame.write.format('com.databricks.spark.csv').option('header','true').mode('overwrite').save(s3_output)

job.commit()
