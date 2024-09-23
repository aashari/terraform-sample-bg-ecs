import os
import boto3

# Get environment variables
s3_bucket = os.getenv('S3_BUCKET')
s3_key = os.getenv('FILE_TO_SERVE')

# Initialize AWS client
s3_client = boto3.client('s3')

# Download the S3 object
s3_client.download_file(s3_bucket, s3_key, '/data/index.html')
