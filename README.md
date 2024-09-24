# ECS Blue/Green Deployment with Terraform

## Project Overview

This project demonstrates the implementation of a scalable and highly available web application using AWS ECS (Elastic Container Service) with Blue/Green deployment capabilities. The infrastructure is defined and managed using Terraform, enabling Infrastructure as Code (IaC) practices.

## Architecture

The solution implements a 3-tier architecture with the following components:

1. **Networking**: A custom VPC with public and private subnets across multiple Availability Zones.
2. **Compute**: ECS Fargate for running containerized applications.
3. **Load Balancing**: Application Load Balancer (ALB) for distributing traffic.
4. **CI/CD**: AWS CodePipeline with CodeBuild and CodeDeploy for continuous integration and deployment.
5. **Storage**: S3 for storing static web content and deployment artifacts.
6. **Configuration**: AWS Systems Manager (SSM) Parameter Store for managing application configuration.
7. **Monitoring**: CloudWatch for logging and monitoring.

## Key Features

- **Blue/Green Deployments**: Utilizes AWS CodeDeploy for zero-downtime deployments.
- **Scalability**: ECS Fargate allows easy scaling of container instances.
- **Security**: Implements network isolation with public and private subnets.
- **Flexibility**: Easily updateable web content through S3 and SSM parameters.
- **Observability**: Integrated logging with CloudWatch.

## Prerequisites

- AWS Account
- Terraform (version 0.12+)
- AWS CLI configured with appropriate permissions
- GitHub repository for application code

## Project Structure

```
.
├── 00-data.tf
├── 01-main.tf
├── 02-network.tf
├── 03-bucket.tf
├── 04-builder.tf
├── 05-pipeline.tf
├── 05-service.role.tf
├── 05-service.tf
├── README.md
├── modules
│   └── builder
│       ├── data.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
└── services
    ├── deployment
    │   └── buildspec.yml
    ├── downloader
    │   ├── Dockerfile
    │   ├── buildspec.yml
    │   └── download_script.py
    ├── webcontent
    │   ├── buildspec.yml
    │   └── objects
    │       ├── index-01.html
    │       ├── index-02.html
    │       └── index-03.html
    └── webserver
        ├── Dockerfile
        ├── buildspec.yml
        └── nginx.conf
```

## Architecture and Flow

### Architecture Diagram

```
graph TB
    subgraph GitHub
        A[GitHub: Repository]
    end

    subgraph AWS["AWS Cloud"]
        subgraph CodePipeline["CodePipeline: Web Server Pipeline"]
            B[Source]
            C[Build]
            D[Prepare Deployment]
            E[Deploy]
        end

        F[CodeBuild: Build Content]
        G[CodeBuild: Build Downloader]
        H[CodeBuild: Build WebServer]
        
        subgraph CodeDeploy["CodeDeploy: Blue/Green Deployment"]
            J[Blue/Green Deployment]
        end

        subgraph VPC["VPC: Main"]
            subgraph PublicSubnets["Public Subnets"]
                K[NAT Gateway]
                L[ALB: Web Server]
            end
            subgraph PrivateSubnets["Private Subnets"]
                M[ECS Cluster]
                subgraph ECSService["ECS Service"]
                    N[Blue Task Set]
                    O[Green Task Set]
                end
            end
        end

        subgraph DeploymentPreparation["Deployment Preparation"]
            I[CodeBuild: Prepare Artifacts]
            Q[(S3: Artifacts)]
        end

        P[(S3: Web Content)]
        subgraph ECR["Amazon ECR"]
            R[(ECR: Downloader)]
            S[(ECR: WebServer)]
        end
        
        subgraph PARAMETER["Amazon SSM"]
            T[SSM: Parameter Store]
        end
        
    end

    A -->|Trigger| B
    B --> C
    C --> F & G & H & D
    D --> I
    I -->|Create| Q
    D --> E
    E -->|Use| J
    F -->|Upload| P
    G -->|Push| R
    H -->|Push| S
    J -->|Deploy| ECSService
    L -->|Route| N & O
    ECSService -->|Pull| ECR
    ECSService -->|Download| P
    N & O -->|Serve| L
    K -->|Internet Access| PrivateSubnets
```

### Deployment Flow

1. **Source**: The process begins when changes are pushed to the GitHub repository.

2. **Build**: AWS CodePipeline triggers a CodeBuild job, which:
   - Builds Docker images for the Downloader and Web Server containers
   - Pushes these images to Amazon ECR

3. **Deploy**: CodeDeploy manages the Blue/Green deployment:
   - Creates a new (Green) Task Definition with updated container images
   - Deploys the new Task Definition to the ECS Cluster
   - Routes traffic gradually from the old (Blue) to the new (Green) version

4. **Application**: The ECS Task runs two containers:
   - Downloader: Fetches the specified HTML file from S3 based on the SSM Parameter
   - Web Server: Serves the downloaded HTML file

5. **Load Balancing**: The Application Load Balancer distributes incoming traffic to the active Task Definition.

6. **Monitoring**: CloudWatch collects logs and metrics from the ECS Cluster and other AWS services.

This architecture ensures high availability, scalability, and enables zero-downtime deployments through the Blue/Green deployment strategy.

## Setup and Deployment

1. Clone this repository:
   ```
   git clone <repository-url>
   cd <repository-name>
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Review and modify variables in `01-main.tf` as needed.

4. Plan the Terraform execution:
   ```
   terraform plan
   ```

5. Apply the Terraform configuration:
   ```
   terraform apply
   ```

6. Confirm the changes and type `yes` when prompted.

## Usage

After deployment:

1. Access the web application via the ALB DNS name (output after Terraform apply).
2. Update the SSM parameter to change the served HTML file.
3. Trigger a new deployment through the CodePipeline to see Blue/Green deployment in action.

## Monitoring and Logging

- Access CloudWatch Logs to view application and ECS cluster logs.
- Monitor the ECS cluster, services, and tasks through the AWS ECS console.
- View deployment history and status in the AWS CodeDeploy console.

## Cleanup

To destroy the created resources:

```
terraform destroy
```


Confirm the destruction by typing `yes` when prompted.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- AWS Documentation
- Terraform Documentation
- The open-source community for various tools and libraries used in this project
