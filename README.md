# aws-capstone-exam
# Terraform Infrastructure – Part 2

This repository contains Terraform code to provision AWS infrastructure.

## Resources Created
- VPC (10.0.0.0/16)
- Public subnets (10.0.1.0/24, 10.0.2.0/24)
- Private subnets (10.0.3.0/24, 10.0.4.0/24)
- Internet Gateway and Route Tables
- Security Groups (Web and RDS)
- 2 EC2 instances
- Application Load Balancer (HTTP port 80)
- RDS MySQL (db.t3.micro)

## Notes
Terraform state files and sensitive variables are excluded using `.gitignore`.
