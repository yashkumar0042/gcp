# AWS Terraform Web + RDS Demo

This project creates:

- 1 VPC
- 1 public subnet for an Ubuntu EC2 Apache/PHP web server
- 2 private DB subnets for RDS MySQL because RDS DB subnet groups need two AZs
- Internet Gateway and public route table
- Security group for web: HTTP from internet, SSH from your configured CIDR
- Security group for RDS: MySQL only from the web EC2 security group
- Private RDS MySQL instance
- A simple PHP page that connects to the database and stores page visits

## Prerequisites

- AWS CLI configured with credentials
- Terraform installed
- Existing EC2 key pair if you want SSH access

## Run

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region       = "ap-south-1"
project_name     = "tf-web-rds-demo"
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
key_name         = "YOUR_EXISTING_EC2_KEY_PAIR_NAME"
```

Then run:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After apply, open the `web_url` output in your browser.

To print the DB password:

```bash
terraform output -raw db_password
```

## Destroy

```bash
terraform destroy
```

## Notes

This is a learning/demo setup. For production, use HTTPS, ALB, private app subnets, Secrets Manager or SSM Parameter Store for DB credentials, NAT if app instances need private outbound internet, RDS backups, deletion protection, and stricter SSH access.
