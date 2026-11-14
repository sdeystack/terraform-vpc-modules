# Architecture — VPC + Modules + Remote State

## Diagram

```
                          us-east-1
  +-----------------------------------------------------------+
  |  VPC 10.0.0.0/16 (dev)                                    |
  |                                                           |
  |  us-east-1a                  us-east-1b                  |
  |  +------------+              +------------+               |
  |  | public     |              | public     |               |
  |  | 10.0.1.0/24|              | 10.0.2.0/24|               |
  |  | ALB node   |              | ALB node   |               |
  |  | NAT gw     |              |            |               |
  |  +------------+              +------------+               |
  |  +------------+              +------------+               |
  |  | private    |              | private    |               |
  |  | 10.0.11/24 |              | 10.0.12/24 |               |
  |  | EC2 (web)  |              | (empty)    |               |
  |  +------------+              +------------+               |
  |                                                           |
  |  Internet gateway: public subnets only                    |
  |  NAT gateway: one, in public AZ-a; both private subnets   |
  |  route outbound traffic through it                        |
  +-----------------------------------------------------------+
  State (outside the VPC): S3 bucket + DynamoDB lock table
```

## How a request flows

1. A browser asks for the ALB's DNS name.
2. The ALB, in the public subnets, accepts the request on port 80. Its security group allows the world in on port 80.
3. The ALB forwards the request to the EC2 instance. The instance's security group allows only the ALB in on port 80.
4. The instance answers. It has no public IP, so the answer goes back through the ALB.
5. When the instance itself needs the internet (installing its web server at first boot), its traffic leaves through the NAT gateway. The NAT gateway allows outbound requests and their replies, but never lets the internet start a connection in.

## Design decisions

- **Two AZs, two public + two private subnets.** The ALB requires at least two AZs. Spreading subnets across AZs is the habit, even when only one instance runs.
- **Modules, not flat files.** Project 1 used flat files. Here the VPC and compute recipes live once in `modules/` and are called by each environment. The same code, different settings.
- **Folders per environment, not workspaces.** `envs/dev` and `envs/prod` are separate folders with separate backend keys. Workspaces would share one folder and switch state by name; folders are more explicit and harder to apply to the wrong environment by accident. Either pattern is defensible; explicitness wins for a lab.
- **Remote state with locking.** State lives in a versioned, encrypted, private S3 bucket. A DynamoDB table holds a lock during each apply. Versioning means a bad state write can be rolled back from the bucket's history.
- **Bootstrap as a separate, local-state setup.** The bucket and table must exist before they can be a backend. The bootstrap folder solves the chicken-and-egg with its own local state, and it is destroyed last.
- **Partial backend configuration.** The `backend "s3" {}` block in each environment is empty; the real values come from `backend.hcl` at init time. The bucket name is created by the bootstrap step, so it cannot be written into the code in advance.
- **AL2023 + t3.micro.** The newest Amazon Linux, and the smallest instance type that stays free-tier eligible on a new account. The instance runs one web server serving one page.
- **No IAM role on the instance.** The instance makes no AWS API calls. Least privilege starts with giving nothing.

## Trade-offs (deliberate lab limits)

- **One NAT gateway, not one per AZ.** Cheaper (NAT gateways charge hourly), but a single point of failure, and the second AZ's private subnet sends its outbound traffic across AZs. Production: one NAT per AZ.
- **HTTP only, no TLS.** A certificate and DNS name would add setup without teaching networking. Production: HTTPS with ACM on port 443.
- **ALB open to the world.** Fine for a short-lived demo page. Production: restrict, or put CloudFront/WAF in front.
- **Single instance, no auto scaling.** The point here is the network, not scale. A second instance and an auto scaling group would be the next step.
- **State bucket `force_destroy`.** Lets `terraform destroy` empty the bucket in the lab. Never in production.
- **Prod is a skeleton.** The pattern is shown; a second deployment would double the hourly cost and add nothing to the learning. Prod values (CIDR, name prefix) are set so the folder is ready if it is ever wanted.

## What prod would change

- One NAT gateway per AZ, with a route table per private subnet.
- HTTPS listener with an ACM certificate; HTTP redirects to HTTPS.
- ALB access logs to S3; CloudWatch alarms on unhealthy targets and 5xx responses.
- Auto scaling group across both private subnets instead of one instance.
- Separate AWS account for prod, with state in that account's own bucket.
- CI that runs `terraform plan` on pull requests and applies only after review.

## Destroy order (and why)

1. `envs/dev` destroy: removes the VPC, NAT gateway, ALB, and instance. Verify with empty `terraform state list` and a console check that the NAT gateway is gone.
2. `bootstrap` destroy: removes the bucket and lock table. This must come last, because destroying dev writes its final state to the bucket.

Destroying in the wrong order strands the dev state file in a bucket that no longer exists as a backend, and the bootstrap destroy would fail on a non-empty bucket without `force_destroy`.

## Cost watch-outs

- The NAT gateway and the ALB charge by the hour from creation until deletion, whether or not any traffic flows. Deploy, verify, destroy in the same session.
- The t3.micro is free-tier eligible on a new account (750 hours/month for the first 12 months). Outside the free tier it is a few cents per hour.
- Data processed through the NAT gateway has a per-GB charge; a lab page serving a few requests is negligible.
- Always confirm the real number in Billing after the session. Spend data can lag up to 24 hours.
