terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.10.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ---------------- VPC ----------------
resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# ---------------- Key Pair ----------------
resource "aws_key_pair" "mykey" {
  key_name   = "terraform-key"
  public_key = file(var.public_key_path)
}


# ---------------- Subnets -------------
# Public (Bastion, ALB, NAT)
resource "aws_subnet" "pubsub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "pubsub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

# Private (App servers)
resource "aws_subnet" "pvtsub1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
}
resource "aws_subnet" "pvtsub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1b"
}

# ---------------- Internet + Routes ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

# Public RT (IGW)
resource "aws_route_table" "RTpub" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rtapub1" {
  subnet_id      = aws_subnet.pubsub1.id
  route_table_id = aws_route_table.RTpub.id
}

resource "aws_route_table_association" "rtapub2" {
  subnet_id      = aws_subnet.pubsub2.id
  route_table_id = aws_route_table.RTpub.id
}

# NAT Gateways per AZ
resource "aws_eip" "eipnat" {
  count  = 2
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw1" {
  allocation_id = aws_eip.eipnat[0].id
  subnet_id     = aws_subnet.pubsub1.id
}

resource "aws_nat_gateway" "natgw2" {
  allocation_id = aws_eip.eipnat[1].id
  subnet_id     = aws_subnet.pubsub2.id
}

# Private RTs (each AZ → NAT in same AZ)
resource "aws_route_table" "RTpvtsub1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw1.id
  }
}

resource "aws_route_table" "RTpvtsub2" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw2.id
  }
}

resource "aws_route_table_association" "rtapvtsub1" {
  subnet_id      = aws_subnet.pvtsub1.id
  route_table_id = aws_route_table.RTpvtsub1.id
}

resource "aws_route_table_association" "rtapvtsub2" {
  subnet_id      = aws_subnet.pvtsub2.id
  route_table_id = aws_route_table.RTpvtsub2.id
}

# ---------------- Security Groups -------------
# ALB SG (internet → 80)
resource "aws_security_group" "albSg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.myvpc.id

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

# Bastion SG (SSH only from your IP)
resource "aws_security_group" "bastionSg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web/App SG (ALB → 8080; Bastion → 22)
resource "aws_security_group" "webSg" {
  name   = "web-sg"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.albSg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastionSg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- Bastion Host ----------------
resource "aws_instance" "bastion" {
  ami                         = "ami-02d26659fd82cf299"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pubsub1.id
  vpc_security_group_ids      = [aws_security_group.bastionSg.id]
  key_name                    = aws_key_pair.mykey.key_name
  associate_public_ip_address = true

  tags = {
    Name = "bastion"
  }
}

# ---------------- ALB ----------------
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false # Internet-facing ALB   
  load_balancer_type = "application"
  security_groups    = [aws_security_group.albSg.id]
  subnets            = [aws_subnet.pubsub1.id, aws_subnet.pubsub2.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "8080"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward" #send traffic to the specified target group
  }
}

# ---------------- Launch Template + ASG ----------
resource "aws_launch_template" "lt" {
  name_prefix   = "lt-"
  image_id      = "ami-02d26659fd82cf299"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.mykey.key_name

  network_interfaces {
    security_groups = [aws_security_group.webSg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y httpd
    sed -i 's/^Listen 80$/Listen 8080/' /etc/httpd/conf/httpd.conf
    systemctl enable httpd
    systemctl restart httpd
    echo "Hello from ASG $(hostname) on 8080" > /var/www/html/index.html
  EOF
  )
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  vpc_zone_identifier       = [aws_subnet.pvtsub1.id, aws_subnet.pvtsub2.id]
  target_group_arns         = [aws_lb_target_group.tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 90

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-webserver"
    propagate_at_launch = true #apply this tag to every instance launched by the ASG
  }
}

# ---------------- Outputs ----------------
output "vpc_id" {
  value = aws_vpc.myvpc.id
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}

output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}
