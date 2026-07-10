# Video Streaming App

This project deploys a lab-grade video processing workflow. A web EC2 instance accepts uploads, S3 sends notifications to SQS, and a worker EC2 instance converts videos into HLS output with FFmpeg.

## Architecture Diagram

![Architecture diagram](architecture.png)

## Architecture

- `modules/storage` creates private input/output S3 buckets and a DynamoDB video catalog.
- `modules/queue` creates the video SQS queue, DLQ, queue policy, and S3 event notification.
- `modules/security` creates separate worker and web security groups.
- `modules/compute` creates the web and worker EC2 instances, IAM roles, instance profiles, and systemd-backed user data.

Data flow:

1. Users upload a video through the web app.
2. The web app stores the original object in the input bucket and records catalog state.
3. S3 sends an object-created event to SQS.
4. The worker consumes the queue, reads the input object, writes HLS output, and updates DynamoDB.
5. The web app lists processed videos and serves output from the private output bucket.

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

Open the web app:

```bash
terraform output -raw web_url
```

## Tear Down

The buckets use `force_destroy = true` for lab cleanup, but for production you should empty and review buckets manually first.

```bash
terraform destroy
cd backend
terraform destroy
```

Destroy the main lab before destroying `backend/`. Only destroy the backend after confirming you no longer need the state history stored in S3.

## Best Practices

- Do not commit state, `.tfvars`, generated plans, `backend.hcl`, or uploaded media.
- Pin and verify third-party FFmpeg binaries before production use.
- Use CloudFront and a production HLS player for real streaming workloads.
- Keep EC2 access through SSM instead of public SSH.
- Destroy the lab when finished to avoid EC2, S3, and DynamoDB costs.
