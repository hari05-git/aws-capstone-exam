########################################
# Data: Get 2 Availability Zones + AMI
########################################
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

########################################
# Network Topology
########################################

# VPC: 10.0.0.0/16
resource "aws_vpc" "task_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "task-vpc" }
}

# Public Subnet 1: 10.0.1.0/24 in AZ1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.task_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet-1" }
}

# Public Subnet 2: 10.0.2.0/24 in AZ2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.task_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = local.azs[1]
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet-2" }
}

# Private Subnet 1: 10.0.3.0/24 in AZ1
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.task_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = local.azs[0]

  tags = { Name = "private-subnet-1" }
}

# Private Subnet 2: 10.0.4.0/24 in AZ2
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.task_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = local.azs[1]

  tags = { Name = "private-subnet-2" }
}

# Internet Gateway
resource "aws_internet_gateway" "task_igw" {
  vpc_id = aws_vpc.task_vpc.id
  tags   = { Name = "task-igw" }
}

# Public Route Table with 0.0.0.0/0 -> IGW
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.task_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.task_igw.id
  }

  tags = { Name = "public-rt" }
}

# Associate Public RT to both public subnets
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table (NO direct internet)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.task_vpc.id
  tags   = { Name = "private-rt" }
}

# Associate Private RT to both private subnets
resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

########################################
# Security Groups
########################################

# Web SG: HTTP 80 from anywhere + SSH 22 from your IP
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Web SG: HTTP from anywhere, SSH from my IP"
  vpc_id      = aws_vpc.task_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web-sg" }
}

# ALB SG: HTTP 80 from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "ALB SG: Allow HTTP from anywhere"
  vpc_id      = aws_vpc.task_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# RDS SG: MySQL 3306 ONLY from Web SG
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "RDS SG: Allow MySQL only from web-sg"
  vpc_id      = aws_vpc.task_vpc.id

  ingress {
    description     = "MySQL from web-sg"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-sg" }
}

########################################
# Compute: 2 EC2 Instances in Public Subnets
########################################
resource "aws_instance" "web_1" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    echo "<h1>Web Server 1</h1>" > /var/www/html/index.html
    systemctl start httpd
  EOF

  tags = { Name = "web-server-1" }
}

resource "aws_instance" "web_2" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    echo "<h1>Web Server 2</h1>" > /var/www/html/index.html
    systemctl start httpd
  EOF

  tags = { Name = "web-server-2" }
}

########################################
# Load Balancer: ALB in Public Subnets (Port 80)
########################################
resource "aws_lb" "task_alb" {
  name               = "task-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "task-alb" }
}

resource "aws_lb_target_group" "task_tg" {
  name     = "task-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.task_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = { Name = "task-tg" }
}

resource "aws_lb_target_group_attachment" "attach_web1" {
  target_group_arn = aws_lb_target_group.task_tg.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach_web2" {
  target_group_arn = aws_lb_target_group.task_tg.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.task_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.task_tg.arn
  }
}

########################################
# Database Layer: RDS MySQL in Private Subnets
########################################

# DB Subnet Group using two private subnets
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = { Name = "db-subnet-group" }
}

# RDS MySQL instance (Free tier type: db.t3.micro)
resource "aws_db_instance" "mysql" {
  identifier             = "task-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
}
