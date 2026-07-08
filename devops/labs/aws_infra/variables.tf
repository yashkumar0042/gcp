variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "tf-web-rds-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into EC2. Keep your public IP /32 for safety. Example: 203.0.113.10/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name for SSH access. Leave empty to disable SSH key login."
  type        = string
  default     = ""
}

variable "web_instance_type" {
  description = "EC2 instance type for web server"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "appuser"
}
