# URL Shortener

This project deploys a serverless URL shortener with Terraform. It uses DynamoDB for URL mappings, two separately permissioned Lambda functions, and a regional REST API Gateway with an API key and usage plan.

## Architecture Diagram

![Architecture diagram](architecture.png)

## Architecture

- `modules/storage` creates the encrypted DynamoDB URL table with point-in-time recovery.
- `modules/lambda` creates the create and redirect Lambdas, CloudWatch log groups, and least-privilege IAM roles.
- `modules/api` creates API Gateway resources, Lambda invoke permissions, an API key, throttling, and quota controls.

Data flow:

1. `POST /create` stores a long URL in DynamoDB and returns a short ID.
2. `GET /{id}` reads the long URL and returns an HTTP redirect.
3. Only the create Lambda can call `dynamodb:PutItem`; only the redirect Lambda can call `dynamodb:GetItem`.

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

Get the API key after apply:

```bash
terraform output -raw api_key_retrieval_command
```

Use the printed command, then call:

```bash
curl -X POST "$(terraform output -raw invoke_url)/create" \
  -H "x-api-key: API_KEY_HERE" \
  -H "content-type: application/json" \
  -d '{"url":"https://example.com"}'
```

## Tear Down

```bash
terraform destroy
cd backend
terraform destroy
```

Destroy the main lab before destroying `backend/`. Only destroy the backend after confirming you no longer need the state history stored in S3.

## Best Practices

- Do not commit `terraform.tfvars`, state files, generated plans, or API keys.
- Do not commit `backend.hcl`; it is generated from the bootstrap output.
- Keep API keys server-side for real applications.
- Use remote state with locking for team or production use.
- Review `terraform plan` before applying.
- Destroy lab resources when finished to avoid cost.
