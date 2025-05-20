# AWS Microservices Demo

This project demonstrates a microservices-based architecture using Python, Docker, AWS services, Terraform, and GitHub Actions CI/CD. It includes infrastructure and service definitions that work together to simulate a small cloud-native system with message passing and file storage.

## Overview

The system consists of two microservices:

- **Producer Service (Flask API)**: Exposes a POST endpoint. It receives data, validates an authentication token from AWS SSM Parameter Store, and sends the payload to an AWS SQS queue.
- **Consumer Service**: Continuously polls the SQS queue for new messages. When a message is received, it stores the content as a JSON file in an S3 bucket.

The services are containerized using Docker and can be tested locally using `docker-compose`, or deployed to AWS using Terraform.

---

## Architecture Summary

- **Docker**: Both services run in isolated containers.
- **Terraform**: Provisions infrastructure including:
  - ECS Cluster and Tasks (Fargate)
  - Application Load Balancer (ALB)
  - IAM roles and policies
  - SQS queue
  - S3 bucket
  - SSM parameter for token authentication
  - Security groups and networking
- **GitHub Actions**: Handles CI/CD processes (currently disabled for safety)

---

## File Structure
```bash
aws-microservices-demo/
├── microservice-1/ # Producer service (Flask)
│ ├── app.py
│ ├── Dockerfile
│ └── requirements.txt
├── microservice-2/ # Consumer service
│ ├── consumer.py
│ ├── Dockerfile
│ └── requirements.txt
├── terraform/ # Infrastructure as code
│ ├── main.tf
│ ├── ecs.tf
│ ├── elb.tf
│ ├── iam.tf
│ ├── sqs.tf
│ ├── s3.tf
│ └── variables.tf
├── .env.example # Sample environment config
├── docker-compose.yml # For local testing
├── VERSION # CI-generated versioning
└── README.md
```

## Local Setup and Testing

### Prerequisites

- Docker and Docker Compose
- AWS CLI configured with access to SQS, S3, SSM, etc.
- Valid SSM parameter and AWS credentials available locally (via `~/.aws/credentials`)

### Steps

1. Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/aws-microservices-demo.git
cd aws-microservices-demo
cp .env.example .env
docker-compose up --build

curl -X POST http://localhost:8080/ \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your-ssm-token-value",
    "data": {
      "email": "test@example.com",
      "email_timestream": 1716111111
    }
  }'
```
### Environment Variables

These must be set in a .env file:

```bash
AWS_REGION=us-east-2
SSM_PARAM_NAME=/myapp/auth/token
SQS_QUEUE_URL=https://sqs.us-east-2.amazonaws.com/123456789012/your-queue
S3_BUCKET=your-s3-bucket
S3_FOLDER=emails/
```
---

### Infrastructure with Terraform

This project provisions the following AWS infrastructure using Terraform:

- ECS cluster (Fargate) with two services (Producer & Consumer)

- Application Load Balancer (ALB) routing HTTP traffic to the Producer

- SQS queue for message passing between services

- S3 bucket for storing processed messages

- SSM Parameter Store for token-based authentication

- IAM roles and policies with access to S3, SQS, and SSM

- Security groups for ECS and ALB access control

All infrastructure is defined in the terraform/ directory and can be deployed manually:
```bash
cd terraform
terraform init
terraform apply -var="image_tag=1.0.X"
```
To destroy the stack:
terraform destroy -var="image_tag=1.0.X"

---
### VERSION File

This project includes a VERSION file that is automatically updated during the CI workflow. It contains the current version of the Docker images being built and deployed.

The format used is 1.0.X, where X is incremented on each CI run.

This version is passed as a variable to Terraform to ensure the correct image is deployed in ECS.

Current version (last build): 1.0.38


---
### CI/CD with GitHub Actions
This project includes GitHub Actions workflows for continuous integration and deployment:

- ci.yml – Build & Push

    Triggered on every push to main

    Builds and tags Docker images for both services

    Pushes images to Docker Hub (latest and versioned)

    Updates and commits the VERSION file

- cd.yml – Deploy Infrastructure

     Deploys AWS infrastructure using Terraform

     Uses the image version defined in the VERSION file

- destroy.yml – Cleanup

     Manually triggered

     Destroys all infrastructure using terraform destroy



