# File Storage App

This project deploys a hybrid serverless file-storage architecture. API Gateway and Lambda issue presigned S3 URLs, S3 events feed an asynchronous metadata path through SQS, DynamoDB stores file metadata, and an EC2 UI proxy keeps the API key out of browser JavaScript.

## Architecture Diagram

![Architecture diagram](architecture.png)

## Architectural Approach

The architecture keeps file bytes out of the API tier. Clients interact with the UI server, the API Lambda returns presigned upload and download URLs, and S3 handles object transfer directly. This pattern reduces pressure on Lambda and API Gateway while keeping the bucket private.

Metadata is handled asynchronously. S3 sends object-created events to SQS, and a separate Lambda consumes those events to update DynamoDB. The EC2 UI proxy is included to demonstrate a safer lab pattern for API key handling: the key stays server-side instead of being embedded in the browser.

## Request/Data Flow

1. Browser requests go to the EC2 UI server.
2. The UI server calls API Gateway using the API key stored on the server.
3. The API Lambda returns presigned upload/download URLs and handles metadata operations.
4. S3 object-created events go to SQS.
5. The metadata Lambda consumes SQS and writes file metadata to DynamoDB.

## Key AWS Services

- S3 stores private, versioned file objects and emits object-created notifications.
- API Gateway exposes the file API with an API key, usage plan, throttling, and quota controls.
- Lambda issues presigned URLs and processes metadata events with separate IAM roles.
- SQS and a dead-letter queue buffer S3 events before metadata writes.
- DynamoDB stores encrypted file metadata, and EC2 hosts the UI proxy.

## Operational Considerations

- Presigned URLs are a strong fit when clients need direct S3 transfer without public buckets.
- SQS decouples object creation from metadata persistence, so temporary metadata failures do not block uploads.
- Production systems should add user identity, per-user authorization, object scanning, lifecycle policies, and more robust API key or token management.

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

Open the UI:

```bash
terraform output -raw ui_url
```

## Tear Down

The S3 bucket uses `force_destroy = true` for lab cleanup. Review contents before destroying if you used real files.

```bash
terraform destroy
cd backend
terraform destroy
```

Destroy the main lab before destroying `backend/`. Only destroy the backend after confirming you no longer need the state history stored in S3.

## Best Practices

- Do not embed API keys in browser JavaScript.
- Do not commit `terraform.tfvars`, local state, generated plans, `backend.hcl`, or API keys.
- Keep S3 public access blocked.
- Use remote state with locking outside solo lab work.
- Destroy the lab when finished to avoid EC2, API Gateway, S3, and DynamoDB costs.
