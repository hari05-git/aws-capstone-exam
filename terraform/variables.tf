variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "my_ip_cidr" {
  description = "Your IP for SSH access, e.g., 1.2.3.4/32"
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name in us-east-1"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}
