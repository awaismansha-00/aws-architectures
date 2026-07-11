# AWS Architecture Labs in Terraform

This repository is a portfolio of AWS architecture patterns implemented with modular Terraform. Each lab focuses on a different application shape, from serverless request/response APIs to event-driven processing, blue/green traffic shifting, and three-tier web systems.

The goal is not only to provision resources, but to show how the services work together, where state lives, how requests or events move through the system, and what operational tradeoffs each design introduces.

| Project | Architectural Pattern | Core Services |
| --- | --- | --- |
| `01-url-shortener` | Serverless request/response API | API Gateway, Lambda, DynamoDB |
| `02-blue-green-deployment` | Weighted blue/green deployment | VPC, EC2, Application Load Balancer |
| `03-chat-application` | Serverless real-time and event-driven backend | WebSocket API, Lambda, DynamoDB, SQS |
| `04-video-streaming-app` | Event-driven media processing pipeline | S3, SQS, EC2/FFmpeg, DynamoDB |
| `05-file-storage-app` | Hybrid serverless file-storage workflow | API Gateway, Lambda, S3, SQS, DynamoDB, EC2 |
| `06-photo-sharing-app` | Three-tier web application with event extensions | ALB, EC2, RDS, Secrets Manager, S3, Lambda |

Each directory is a separate Terraform root with project-local modules under `modules/` and a project-local backend bootstrap under `backend/`. Any lab folder can be copied into its own GitHub repository without depending on shared Terraform code from this parent repo.

Read each project's `README.md` for the architecture narrative, then bootstrap its remote state before running the main lab:

```bash
terraform fmt -recursive
cd backend
terraform init
terraform apply
terraform output -raw backend_config > ../backend.hcl
cd ..
terraform init -backend-config=backend.hcl
terraform validate
terraform plan
```

Backend bootstrap resources require an explicit apply when you are ready. Review costs, apply one lab at a time, destroy the main lab first, then destroy `backend/` only when the state history is no longer needed.
