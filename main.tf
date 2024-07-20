# Terraform Settings Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Optional but recommended in production
    }
  }
}

# Provider Block
provider "aws" {
  profile = "default" # AWS Credentials Profile configured on your local desktop terminal  $HOME/.aws/credentials
  region  = var.myregion
}

resource "aws_vpc" "main" {
  cidr_block= var.myvpccidr
}

resource "aws_subnet" "public_subnet"{
  vpc_id = var.myvpccidr
  cidr_block = var.mysubnetcidr[count.index]
  count = 5
}

resource "aws_internet_gateway" "main"{
  vpc_id = var.myvpccidr

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "main"{
  vpc_id = var.myvpccidr

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "route-table123"
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id = var.mysubnetcidr[count.index]
  route_table_id = aws_route_table.main.id
  count = 5
}

resource "aws_instance" "example"{
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = var.ec2type[count.index]
  tags = local.common_tags
  count = 5
}
  

resource "aws_security_group" "example" {
  name = "example-sg"
  vpc_id = var.myvpccidr

  dynamic "ingress" {
    for_each = var.ingress_rules
    iterator = port
    content {
      from_port = port.value
      to_port = port.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}


resource "aws_s3_bucket" "new_bucket" {
  bucket_prefix = "my-first-bucket"
  acl        = "private"
}


resource "aws_lb" "app_lb" {
  name = "app-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.example.id]  
  subnets = var.mysubnetcidr
}

resource "aws_lb_target_group" "app_tg" {
  name = "app-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.myvpccidr

  health_check {
    path = "/"
    protocol = "http"
    interval = 30
    timeout = 5
    healthy_threshold = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port = "80"
  protocol = "http"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
  
resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  count = 5
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id = aws_instance.example[count.index].id
  port = 80
  
}
#Allocation an elastic IP for the NAT gateway.

resource "aws_eip" "example_eip" {
  vpc = true

  tags = {
    Name = "example-eip"
  }
  
}

resource "aws_nat_gateway" "example_nat_gateway" {
 allocation_id = aws_eip.example_eip.id 
 subnet_id = var.mysubnetcidr[count.index]
 count = 5
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_execution"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "example" {
  filename         = "lambda_function_payload.zip"
  function_name    = "example_lambda_function"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
 # source_code_hash = filebase64sha256("lambda_function_payload.zip")
  runtime          = "nodejs14.x"
  timeout          = 10
}

# Optional: Create Lambda Function Alias (Optional)
resource "aws_lambda_alias" "example" {
  name             = "example_alias"
  function_name    = aws_lambda_function.example.function_name
  function_version = aws_lambda_function.example.version
}




