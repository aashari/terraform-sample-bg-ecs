# Use Amazon Linux 2 as the base image
FROM amazonlinux:2

# Set the working directory in the container
WORKDIR /app

# Install AWS CLI
RUN yum update -y && \
    yum install -y aws-cli && \
    yum clean all

# Copy the script into the container
COPY script.sh .

# Make the script executable
RUN chmod +x script.sh

# Run the script
CMD ["./script.sh"]
