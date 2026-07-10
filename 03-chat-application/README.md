# Chat Application

This project deploys a serverless WebSocket chat backend. It uses API Gateway WebSocket APIs, DynamoDB connection/history tables, SQS for message archiving, and three least-privilege Lambda functions.

## Architecture Diagram

![Architecture diagram](architecture.png)

## Architecture

- `modules/storage` creates encrypted DynamoDB tables for active connections and chat history.
- `modules/queue` creates the chat log SQS queue and dead-letter queue.
- `modules/lambda` creates the handler, archiver, and authorizer Lambdas with separate IAM roles.
- `modules/websocket_api` creates the WebSocket API, `$connect` Lambda authorizer, routes, stage throttling, Lambda permissions, and the handler `execute-api:ManageConnections` policy.

Data flow:

1. Clients connect with `?token=...`; the authorizer checks the token.
2. The handler stores/removes active connections and broadcasts messages.
3. Chat messages are sent to SQS.
4. The archiver consumes SQS messages and writes chat history to DynamoDB.

## Remote State

The `backend/` folder bootstraps this project's Terraform state backend. It creates a private versioned S3 bucket for state, a DynamoDB table for state locking, and emits a `backend.hcl` file used by the main project. The bootstrap state stays local because the remote backend must exist before the main project can use it.

## Run

Create a local `terraform.tfvars` with a strong connection token:

```hcl
connection_token = "replace-with-at-least-20-random-characters"
```

Then run:

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
terraform apply
```

Connect with a WebSocket client:

```bash
terraform output -raw websocket_url
```

Replace `REDACTED` in the output with your real token.

## Tear Down

```bash
terraform destroy
cd backend
terraform destroy
```

Destroy the main lab before destroying `backend/`. Only destroy the backend after confirming you no longer need the state history stored in S3.

## Best Practices

- Do not commit `terraform.tfvars` because it contains the connection token.
- Do not commit `backend.hcl`; it is generated from the bootstrap output.
- Rotate the token if it is shared accidentally.
- Keep the DLQ and inspect failed archive messages during testing.
- Use real identity-based auth for production chat systems.
- Destroy the lab when finished to avoid ongoing API, SQS, and DynamoDB usage.
