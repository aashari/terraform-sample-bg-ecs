#!/bin/bash

# Check if required environment variables are set
if [ -z "$S3_BUCKET" ] || [ -z "$FILE_TO_SERVE" ]; then
    echo "Error: S3_BUCKET and FILE_TO_SERVE environment variables must be set"
    exit 1
fi

# Create the data directory if it doesn't exist
mkdir -p /data

# Download the S3 object
aws s3 cp "s3://${S3_BUCKET}/${FILE_TO_SERVE}" /data/index.html

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "File successfully downloaded from S3"
else
    echo "Error: Failed to download file from S3"
    exit 1
fi
