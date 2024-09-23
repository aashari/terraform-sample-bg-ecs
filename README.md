## Objective

Configure the following resources on AWS using Terraform:

1. **3-tier VPC**: Set up a Virtual Private Cloud with public and private subnets.
2. **Load-balanced ECS Fargate Service**: Deploy a sample web server (e.g., Nginx) using ECS Fargate with load balancing.
3. **CodeDeploy Resources**: Implement resources for managing blue-green deployment of new service versions.
4. **S3 Bucket**: Create an S3 bucket to store sample HTML files for the web server.
5. **SSM Parameter**: Define an SSM parameter to specify the prefix/key of the HTML file served by the web server.
6. **CloudWatch Logs**: Set up log groups in CloudWatch Logs to collect access and error logs of the web server.

### ECS Task Definition

- **Container 1 (Sidecar Pattern)**: 
  - Runs a script to download the S3 object specified by the SSM parameter (e.g., s3://bucket/v1/index.html).
  - Stores the downloaded file in the task's virtual volume.
  - Passes the SSM parameter value to the container via environment variables defined in the task definition.

- **Container 2 (Web Server)**:
  - Waits for the first container to finish execution.
  - Mounts the virtual volume updated by the script.
  - Serves the downloaded file.
