variable "aws_access_key" {
  type        = string
  default     = ""
  description = "AWS Account Access Key"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  default     = ""
  description = "AWS Account Secret Access Key"
}

variable "db_port" {
  type        = number
  default     = 3306
  description = "MySQL Port"
}

variable "db_master_username" {
  type        = string
  default     = ""
  description = "Database Master Username"
}

variable "db_master_password" {
  type        = string
  default     = ""
  description = "Database Password"
  sensitive   = true
}

# variable "web_tier_user_data" {
#   type        = string
#   default     = ""
#   description = "Web Tier User Data"
# }

# variable "app_tier_user_data" {
#   type        = string
#   default     = ""
#   description = "App Tier User Data"
# }

variable "app_alb_port" {
  type        = number
  default     = 4000
  description = "Application Load Balancer Listening Port"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 Instance Type"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


resource "aws_vpc" "cc-vpc-1" {
  cidr_block           = "10.16.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cc-vpc-1"
  }
}

resource "aws_security_group" "cc-web-alb-sg" {
  name        = "cc-web-alb-sg"
  description = "Allow HTTP access from anywhere"
  vpc_id      = aws_vpc.cc-vpc-1.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cc-web-sg" {
  name        = "cc-web-sg"
  description = "Allow HTTP access from ELB and SSH from EC2 Instance Connect us-east-1 service CIDR"
  vpc_id      = aws_vpc.cc-vpc-1.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.cc-web-alb-sg.id}"]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    #Allow SSH from the EC2 Instance Connect us-east-1 service CIDR
    cidr_blocks = ["18.206.107.24/29"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cc-app-alb-sg" {
  name        = "cc-app-alb-sg"
  description = "Allow HTTP access from Private ELB"
  vpc_id      = aws_vpc.cc-vpc-1.id
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.cc-web-sg.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cc-app-sg" {
  name        = "cc-app-sg"
  description = "Allow HTTP access from Private ELB"
  vpc_id      = aws_vpc.cc-vpc-1.id
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.cc-app-alb-sg.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "cc-db-sg" {
  name        = "cc-db-sg"
  description = "Allow MyAQL access from application layer"
  vpc_id      = aws_vpc.cc-vpc-1.id
  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = ["${aws_security_group.cc-app-sg.id}"]
  }

  egress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = ["${aws_security_group.cc-app-sg.id}"]
  }
}

resource "aws_subnet" "cc-sn-web-a" {
  vpc_id                  = aws_vpc.cc-vpc-1.id
  cidr_block              = "10.16.0.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cc-sn-web-a"
  }
}
resource "aws_subnet" "cc-sn-web-b" {
  vpc_id                  = aws_vpc.cc-vpc-1.id
  cidr_block              = "10.16.16.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "cc-sn-web-b"
  }
}

resource "aws_subnet" "cc-sn-app-a" {
  vpc_id                  = aws_vpc.cc-vpc-1.id
  cidr_block              = "10.16.32.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "cc-sn-app-a"
  }
}
resource "aws_subnet" "cc-sn-app-b" {
  vpc_id                  = aws_vpc.cc-vpc-1.id
  cidr_block              = "10.16.48.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "cc-sn-app-b"
  }
}

resource "aws_subnet" "cc-sn-db-a" {
  vpc_id                  = aws_vpc.cc-vpc-1.id
  cidr_block              = "10.16.64.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "cc-sn-db-a"
  }
}
resource "aws_subnet" "cc-sn-db-b" {
  vpc_id                  = aws_vpc.cc-vpc-1.id
  cidr_block              = "10.16.80.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "cc-sn-db-b"
  }
}

resource "aws_internet_gateway" "cc-igw" {
  vpc_id = aws_vpc.cc-vpc-1.id

  tags = {
    Name = "cc-igw"
  }
}

resource "aws_eip" "cc-eip-nat-gw-a" {
  domain = "vpc"
}

resource "aws_nat_gateway" "cc-nat-gw-a" {
  allocation_id = aws_eip.cc-eip-nat-gw-a.id
  subnet_id     = aws_subnet.cc-sn-web-a.id

  tags = {
    Name = "cc-nat-gw-a"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.cc-igw]
}

resource "aws_eip" "cc-eip-nat-gw-b" {
  domain = "vpc"
}

resource "aws_nat_gateway" "cc-nat-gw-b" {
  allocation_id = aws_eip.cc-eip-nat-gw-b.id
  subnet_id     = aws_subnet.cc-sn-web-b.id

  tags = {
    Name = "cc-nat-gw-a"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.cc-igw]
}

resource "aws_route_table" "cc-web-rt" {
  vpc_id = aws_vpc.cc-vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cc-igw.id
  }

  tags = {
    Name = "cc-web-rt"
  }
}

resource "aws_route_table" "cc-app-rt-a" {
  vpc_id = aws_vpc.cc-vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.cc-nat-gw-a.id
  }

  tags = {
    Name = "cc-app-rt-a"
  }
}

resource "aws_route_table" "cc-app-rt-b" {
  vpc_id = aws_vpc.cc-vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.cc-nat-gw-b.id
  }

  tags = {
    Name = "cc-app-rt-b"
  }
}

resource "aws_route_table" "cc-db-rt-a" {
  vpc_id = aws_vpc.cc-vpc-1.id

  tags = {
    Name = "cc-db-rt-a"
  }
}

resource "aws_route_table_association" "cc-web-rt-assoc-a" {
  subnet_id      = aws_subnet.cc-sn-web-a.id
  route_table_id = aws_route_table.cc-web-rt.id
}

resource "aws_route_table_association" "cc-web-rt-assoc-b" {
  subnet_id      = aws_subnet.cc-sn-web-b.id
  route_table_id = aws_route_table.cc-web-rt.id
}

resource "aws_route_table_association" "cc-app-rt-assoc-a" {
  subnet_id      = aws_subnet.cc-sn-app-a.id
  route_table_id = aws_route_table.cc-app-rt-a.id
}

resource "aws_route_table_association" "cc-app-rt-assoc-b" {
  subnet_id      = aws_subnet.cc-sn-app-b.id
  route_table_id = aws_route_table.cc-app-rt-b.id
}

resource "aws_route_table_association" "cc-db-rt-assoc-a" {
  subnet_id      = aws_subnet.cc-sn-db-a.id
  route_table_id = aws_route_table.cc-db-rt-a.id
}

resource "aws_route_table_association" "cc-db-rt-assoc-b" {
  subnet_id      = aws_subnet.cc-sn-db-b.id
  route_table_id = aws_route_table.cc-db-rt-a.id
}

resource "aws_launch_template" "ec2-web-tier" {
  name_prefix   = "ec2-web-tier"
  instance_type = var.instance_type
  image_id      = "ami-06ca3ca175f37dd66"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 8
      delete_on_termination = true
      volume_type           = "gp2"
    }
  }

  network_interfaces {
    device_index          = 0
    delete_on_termination = true
    security_groups       = ["${aws_security_group.cc-web-sg.id}"]
  }

  user_data = "${base64encode(file("web_user_data.sh"))}"
}

resource "aws_autoscaling_group" "ec2-web-tier-asg" {
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = ["${aws_subnet.cc-sn-web-a.id}", "${aws_subnet.cc-sn-web-b.id}"]

  launch_template {
    id      = aws_launch_template.ec2-web-tier.id
    version = "$Latest"
  }
}

# Create IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "EC2_SSM_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_role_policy_attachment" "cc-ec2-ssm-role-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

# Create an instance profile for the EC2 instance and associate the IAM role
resource "aws_iam_instance_profile" "cc-ec2-ssm-instance-profile" {
  name = "EC2_SSM_Instance_Profile"

  role = aws_iam_role.ec2_role.name
}

resource "aws_launch_template" "ec2-app-tier" {
  name_prefix   = "ec2-app-tier"
  instance_type = var.instance_type
  image_id      = "ami-06ca3ca175f37dd66"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 8
      delete_on_termination = true
      volume_type           = "gp2"
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.cc-ec2-ssm-instance-profile.arn
  }

  network_interfaces {
    device_index          = 0
    delete_on_termination = true
    security_groups       = ["${aws_security_group.cc-app-sg.id}"]
  }

  user_data = "${base64encode(file("app_user_data.sh"))}"
}

resource "aws_autoscaling_group" "ec2-app-tier-asg" {
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = ["${aws_subnet.cc-sn-app-a.id}", "${aws_subnet.cc-sn-app-b.id}"]

  launch_template {
    id      = aws_launch_template.ec2-app-tier.id
    version = "$Latest"
  }
}

#AWS Web ALB
resource "aws_lb" "cc-web-alb" {
  name               = "cc-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cc-web-alb-sg.id]
  subnets            = [aws_subnet.cc-sn-web-a.id, aws_subnet.cc-sn-web-b.id]
}

#AWS Web ALB Listener
resource "aws_lb_listener" "cc-web-alb-listener" {
  load_balancer_arn = aws_lb.cc-web-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.cc-web-alb-tg.arn
    type             = "forward"
  }
}

#AWS ALB Target Group
resource "aws_lb_target_group" "cc-web-alb-tg" {
  name     = "cc-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cc-vpc-1.id
}

#AWS ALB Target Group Attachment to register instances with ALB
resource "aws_autoscaling_attachment" "cc-web-alb-asg-attach" {
  autoscaling_group_name = aws_autoscaling_group.ec2-web-tier-asg.name
  lb_target_group_arn    = aws_lb_target_group.cc-web-alb-tg.arn
}

#AWS App ALB
resource "aws_lb" "cc-app-alb" {
  name               = "cc-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cc-app-alb-sg.id]
  subnets            = [aws_subnet.cc-sn-app-a.id, aws_subnet.cc-sn-app-b.id]
}

#AWS App ALB Listener
resource "aws_lb_listener" "cc-app-alb-listener" {
  load_balancer_arn = aws_lb.cc-app-alb.arn
  port              = var.app_alb_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.cc-app-alb-tg.arn
    type             = "forward"
  }
}

#AWS App Target Group
resource "aws_lb_target_group" "cc-app-alb-tg" {
  name     = "cc-app-tg"
  port     = var.app_alb_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.cc-vpc-1.id
}

resource "aws_autoscaling_attachment" "cc-app-alb-asg-attach" {
  autoscaling_group_name = aws_autoscaling_group.ec2-app-tier-asg.name
  lb_target_group_arn    = aws_lb_target_group.cc-app-alb-tg.arn
}

#RDS Multi-AZ Instance mode
resource "aws_db_subnet_group" "cc-rds-mysql-sn-group" {
  name       = "cc-rds-mysql-sn-group"
  subnet_ids = ["${aws_subnet.cc-sn-db-a.id}", "${aws_subnet.cc-sn-db-b.id}"]

  tags = {
    Name = "cc-rds-mysql-sn-group"
  }
}

locals {
  db_subnet_group_name = "cc-rds-mysql-sn-group"
}


resource "aws_db_instance" "cc-rds-mysql" {
  storage_type           = "gp2"
  allocated_storage      = 8
  identifier             = "cc-rds-mysql"
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.${var.instance_type}"
  username               = var.db_master_username
  password               = var.db_master_password
  port                   = var.db_port
  db_subnet_group_name   = local.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.cc-db-sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = true
  depends_on = [ aws_db_subnet_group.cc-rds-mysql-sn-group ]
}


