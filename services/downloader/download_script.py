import os
import boto3

# Get environment variables
s3_bucket = os.getenv('S3_BUCKET')
ssm_parameter = os.getenv('SSM_PARAMETER')

# Initialize AWS clients
ssm_client = boto3.client('ssm')
s3_client = boto3.client('s3')

# Get the SSM parameter value
response = ssm_client.get_parameter(Name=ssm_parameter)
s3_key = response['Parameter']['Value']

# Download the S3 object
s3_client.download_file(s3_bucket, s3_key, '/data/index.html')
