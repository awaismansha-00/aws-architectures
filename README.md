# AWS Architecture Labs in Terraform

Six independent AWS labs with modular Terraform, least-privilege IAM and reproducible application bootstrapping.

| Project | Architecture |
| --- | --- |
| `01-url-shortener` | API Gateway, Lambda, DynamoDB |
| `02-blue-green-deployment` | VPC, EC2, weighted ALB |
| `03-chat-application` | WebSocket API, Lambda, DynamoDB, SQS |
| `04-video-streaming-app` | S3, SQS, EC2/FFmpeg, DynamoDB |
| `05-file-storage-app` | S3 presigned URLs, Lambda, SQS, API Gateway, EC2 |
| `06-photo-sharing-app` | VPC, RDS, Secrets Manager, S3, Lambda, EC2, ALB |

Each directory is a separate Terraform root with project-local modules under `modules/` and a project-local backend bootstrap under `backend/`. Any lab folder can be copied into its own GitHub repository without depending on shared Terraform code from this parent repo.

Read each project's `README.md`, then bootstrap its remote state before running the main lab:

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
