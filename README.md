# VPC + Reusable Modules + Remote State (Terraform)

Personal lab project. It builds the network and plumbing a real team would use: a VPC with public and private subnets, a load balancer in front of a private EC2 instance, reusable Terraform modules, and remote state in S3 with DynamoDB locking. Everything is deployed with Terraform. No click-ops, no secrets in git, no customer data, destroyed after the demo.

Project 1 (serverless API) proved Lambda + Terraform. This project proves the networking and state-management half: modules, environments, and remote state.

## What it builds, in plain English

- **A VPC is a private network inside AWS.** Think of it as your own building. Inside it, you decide which rooms have a street door and which do not.
- **Public subnets are rooms with a street door.** The Application Load Balancer (ALB) lives here. It is the only thing the internet can reach.
- **Private subnets are rooms with no street door.** The EC2 instance lives here. It has no public IP address. The internet can never start a connection to it.
- **The NAT gateway is the one-way exit.** The private instance can reach out (for example, to download its web-server software) but nothing can reach in through it. One NAT gateway for the whole lab: cheaper, and a deliberate trade-off (see ARCHITECTURE.md).
- **Security groups are guest lists.** The ALB's guest list allows the world in on port 80. The instance's guest list allows only the ALB in on port 80.
- **Modules are reusable recipes.** The VPC recipe and the compute recipe live once, in `modules/`. Dev uses them, and prod would use the same recipes with different settings. Fix the recipe once, every environment benefits.
- **Remote state is the shared notebook.** In Project 1, Terraform's state file lived on the laptop. Here it lives in an S3 bucket, and a DynamoDB table holds a lock so two people (or two terminals) cannot apply at the same time and corrupt it.

## Architecture

```
Internet
    |
    v
Application Load Balancer (public subnets, 2 AZs)
    |  security group: world -> port 80
    v
EC2 instance (private subnet, no public IP)
    |  security group: ALB only -> port 80
    |
    +-- outbound updates via NAT gateway (single, public subnet AZ-a)
    +-- outbound to the internet via internet gateway (public subnets only)

State: S3 bucket (versioned, encrypted, private) + DynamoDB lock table
```

Full design notes, decisions, and trade-offs: [ARCHITECTURE.md](ARCHITECTURE.md).

## Prerequisites

- Personal AWS account (the lab account), MFA on root, the $10/month budget in place.
- Terraform 1.5 or newer, Git, and the AWS CLI for verification checks.
- AWS credentials already configured from Project 1 (`~/.aws/credentials`). Terraform reads them directly; the AWS CLI workaround is only needed for `aws` commands.
- Region: us-east-1.
- Windows notes: use `python`, not `python3`; use `curl.exe` in PowerShell; work from the projects folder in a regular (non-admin) PowerShell window, not `C:\windows\system32`.

## How the session runs

Concept first, then commands, one stage at a time. Do not rush to `apply` before reading the plan.

### Step 0 — Warm-up (no AWS charges)

- Re-read the Project 1 plain-English recap.
- Confirm: region us-east-1, the lab account, budget active, month-to-date cost known.
- Optional: make the `aws` PowerShell function permanent (see the recap appendix). Time-box it; skip if it fights you.

### Step 1 — Remote-state bootstrap (the chicken-and-egg)

The S3 bucket and DynamoDB table must exist before anything can use them as a backend. So they are built first, with their own local state, in `bootstrap/`. That local state file is the one exception: it is fine, because the bootstrap setup is small and runs once.

```powershell
Set-Location "$HOME\projects\terraform-vpc-modules\bootstrap"
terraform init
terraform plan
```

Read the plan. Then apply, and read the outputs: they name the bucket and table.

```powershell
terraform apply
terraform output
```

Copy the two names into `envs/dev/backend.hcl` (copy from `backend.hcl.example`). `backend.hcl` is gitignored; it names your bucket and is environment-specific.

### Step 2 + 3 — VPC module and compute (one apply, verified in order)

Dev calls both modules. A single `terraform apply` in `envs/dev` builds the VPC and the compute together. Verify in order: the network first, then the page in the browser.

```powershell
Set-Location "$HOME\projects\terraform-vpc-modules\envs\dev"
terraform init -backend-config backend.hcl
terraform plan
```

Read the plan. Then apply.

```powershell
terraform apply
terraform output alb_dns_name
```

Open `http://<alb_dns_name>` in a browser. You should see "Hello from i-... in us-east-1a". That page is served by an instance with no public IP, reached only through the load balancer.

### Step 4 — Prod skeleton (no deploy)

`envs/prod/` shows the second-environment pattern: same modules, different variables (different CIDR, different name prefix). It is a sketch. Do not apply it in this session. Deploying prod would need its own backend key (`prod/terraform.tfstate`) and a separate review.

### Verify it works

- `terraform output alb_dns_name`, then open the page in a browser.
- `terraform plan` shows no changes after a successful apply.
- `terraform state list` reads from the S3 backend (state is remote now, not a local file).
- In the console: the NAT gateway exists, the instance has no public IP, the ALB target is healthy.

### My verification run

- Date and time of the deploy: Nov 14, 2026, about 2:50 PM EST
- `terraform plan` summary: 21 to add, 0 to change, 0 to destroy
- ALB page result: browser showed "Hello from i-054c9cf1c96fe6504 in us-east-1a"
- `terraform plan` after apply: no changes
- `terraform state list` result: 22 entries (21 resources + 1 data source), no local terraform.tfstate file

## Destroy (same session — do not leave this running)

The NAT gateway and the load balancer charge by the hour. Deploy, verify, and destroy in the same session. Destroy order matters: dev first, then bootstrap.

```powershell
Set-Location "$HOME\projects\terraform-vpc-modules\envs\dev"
terraform destroy
terraform state list   # should print nothing
```

Check in the console that the NAT gateway is gone. Then destroy the bootstrap setup:

```powershell
Set-Location "$HOME\projects\terraform-vpc-modules\bootstrap"
terraform destroy
```

## Failure handling

- **Backend names wrong in `backend.hcl`:** `terraform init` fails with a "no such bucket/table" style error. Fix the names, run `init` again. Nothing is half-built.
- **State lock stuck:** if an apply is interrupted, the DynamoDB lock can stay held. `terraform force-unlock <lock-id>` releases it, but only after confirming no other apply is running. Never force-unlock blindly.
- **Instance page never loads:** check the ALB target health in the console. If the target is unhealthy, the instance's web server did not start, which usually means user_data could not reach the internet (NAT gateway missing or route table wrong). If the target is healthy but the browser fails, check the ALB security group.
- **NAT gateway still exists after destroy:** check the console and delete it by hand if Terraform missed it. An orphaned NAT gateway keeps charging hourly.

## Cost notes

(Fill in with your own Billing check. Spend data can lag up to 24 hours.)

- Observed cost for my test run: $0.00 as of Nov 14, 2026 (Billing home, month-to-date; spend data can lag up to 24 hours).
- How I checked: Billing home month-to-date spend.
- Expected shape: the NAT gateway and the load balancer charge by the hour, so a short session costs cents; the t3.micro is free-tier eligible on a new account. Leaving the NAT gateway running overnight is the expensive mistake this project teaches you to avoid.

## Trade-offs and what I learned

- One NAT gateway vs one per AZ: one gateway is cheaper for a short lab, but it is a single point of failure, and the second AZ's private subnet sends traffic across AZs; production would use one per AZ.
- Modules vs the flat files in Project 1: the VPC and compute recipes live once and both environments call them, so a fix in one place reaches every environment instead of being copied file by file.
- Remote state vs local state: state in S3 with a DynamoDB lock means the record of what is deployed survives the laptop, and two applies cannot run at once; local state is a single file that only one machine sees.
- What surprised me: how much breaks on small details, parentheses in a tag value, an equals sign in an init flag, and that the fix each time was reading the error and verifying the file.

## Repo layout

```
bootstrap/            S3 bucket + DynamoDB lock table (local state, built first)
modules/
  vpc/                VPC, subnets, internet gateway, NAT, route tables
  compute/            ALB, target group, listener, security groups, EC2 instance
envs/
  dev/                Calls both modules; deployed in this lab
  prod/               Skeleton only: same modules, different variables; NOT deployed
.github/workflows/    CI: terraform fmt + validate only, no deploys, no AWS credentials
```

## Safety and lab limits

- Personal lab account only. No customer or proprietary data anywhere.
- No secrets in git. `backend.hcl` is gitignored; the example file holds placeholders only.
- HTTP only, no TLS: deliberate lab limit. Production would use HTTPS with an ACM certificate.
- ALB open to the world on port 80: deliberate lab limit for a short-lived demo. Production would restrict it.
- Single NAT gateway: cheaper, single point of failure. Production would use one NAT per AZ.
- The state bucket uses `force_destroy`: lab-only convenience so `terraform destroy` can empty it. Never use it on a production state bucket.
- The EC2 instance has no IAM role: it makes no AWS API calls, so it needs no AWS permissions.

## CI

GitHub Actions runs `terraform fmt -check` and `terraform validate` on every push and pull request. It deploys nothing and needs no AWS credentials.
