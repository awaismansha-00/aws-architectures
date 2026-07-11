# Blue/Green Deployment

This project deploys an ALB-based blue/green architecture for controlled application rollouts. Two EC2-backed versions run side by side, and the Application Load Balancer shifts traffic between them using a weighted listener action managed by Terraform.

## Architecture Diagram

![Architecture diagram](architecture.png)

## Architectural Approach

The architecture models a release strategy rather than a single static deployment. Blue and green instances are deployed as independent target groups behind one public Application Load Balancer. Traffic can start entirely on blue, move gradually to green, and roll back by changing the `green_traffic_weight` variable.

The network and security boundaries are intentionally simple for a lab: public subnets host the ALB and instances, while security groups ensure application traffic enters through the load balancer instead of directly from the internet.

## Request/Data Flow

1. Users access the ALB over HTTP.
2. The ALB forwards traffic to blue and green target groups based on `green_traffic_weight`.
3. EC2 instances accept HTTP only from the ALB security group.

## Key AWS Services

- VPC, public subnets, internet gateway, and route tables provide the network foundation.
- EC2 runs the blue and green application versions on Amazon Linux 2023 with encrypted root volumes.
- Application Load Balancer owns the public endpoint, health checks, target groups, and weighted forwarding.
- IAM allows instance access through SSM Session Manager instead of opening SSH.

## Operational Considerations

- Weighted traffic shifting supports gradual rollout, smoke testing, and fast rollback.
- Real production blue/green deployments usually add automated health checks, deployment gates, metrics, and alarms before increasing traffic.
- Keeping ALB and instance security groups separate makes the traffic boundary clear and reduces direct exposure.

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

Change traffic split by editing:

```hcl
green_traffic_weight = 50
```

Then run:

```bash
terraform plan
terraform apply
```

Open the app:

```bash
terraform output -raw alb_url
```

## Tear Down

```bash
terraform destroy
cd backend
terraform destroy
```

Destroy the main lab before destroying `backend/`. Only destroy the backend after confirming you no longer need the state history stored in S3.

## Best Practices

- Do not open SSH to the internet; use SSM Session Manager if instance access is needed.
- Keep ALB and instance security groups separate.
- Use small traffic increments for real blue/green rollouts.
- Do not commit local state, `.tfvars`, generated plans, or `backend.hcl`.
- Destroy the lab when finished to avoid EC2 and ALB costs.
