# Photo Sharing App

This project deploys a photo-sharing architecture with a four-subnet VPC, private RDS MySQL database, private S3 photo bucket, Dockerized EC2 app server, Application Load Balancer, Secrets Manager, and S3-triggered metadata Lambda.

## Architecture Diagram

![Architecture diagram](architecture.png)

## Architecture

- `modules/network` creates the VPC, two public subnets, two private subnets, internet gateway, and public routing.
- `modules/security` creates separate ALB, web, and database security groups.
- `modules/database` creates the RDS subnet group, private MySQL instance, generated password, and Secrets Manager secret.
- `modules/storage` creates the private encrypted S3 photo bucket.
- `modules/web` creates the EC2 app role, instance profile, Docker app server, target group, ALB, and listener.
- `modules/metadata_lambda` creates the Lambda, IAM role, log group, invoke permission, and S3 notification.

Data flow:

1. Users reach the ALB over HTTP.
2. The ALB forwards requests to the EC2 app instance.
3. The app reads database credentials from Secrets Manager and stores photos in S3.
4. RDS is private and accepts MySQL only from the web security group.
5. S3 object-created events invoke the metadata Lambda.

## Remote State

The `backend/` folder bootstraps this project's Terraform state backend. It creates a private versioned S3 bucket for state, a DynamoDB table for state locking, and emits a `backend.hcl` file used by the main project. The bootstrap state stays local because the remote backend must exist before the main project can use it.

## Run

```bash
cp terraform.tfvars.example terraform.tfvars
terraform fmt -recursive

cd backend
terraform init
terraform apply
terraform output -raw backend_config > ../backend.hcl
cd ..

terraform init -backend-config=backend.hcl
terraform validate
terraform plan
terraform apply
```

Open the app:

```bash
terraform output -raw application_url
```

## Tear Down

The RDS final snapshot is skipped for lab cleanup and the S3 bucket uses `force_destroy = true`. Do not use those settings for production data.

```bash
terraform destroy
cd backend
terraform destroy
```

Destroy the main lab before destroying `backend/`. Only destroy the backend after confirming you no longer need the state history stored in S3.

## Best Practices

- Do not commit `.tfvars`, local state, generated plans, `backend.hcl`, secrets, or database credentials.
- Use private subnets for databases and separate security groups for ALB, app, and DB.
- Enable final snapshots and deletion protection for production databases.
- Pin and review the container image before production use.
- Destroy the lab when finished to avoid ALB, EC2, RDS, and S3 costs.
