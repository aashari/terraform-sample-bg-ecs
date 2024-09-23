# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the script into the container
COPY download_script.py .

# Install boto3 and AWS CLI
RUN pip install boto3 awscli

# Run the script
CMD ["python", "download_script.py"]
