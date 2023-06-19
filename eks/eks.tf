variable "backend_bucket_name" {
  type = string
  default = ""
}

variable "backend_bucket_key" {
  type = string
  default = ""
}

variable "region" {
  type = string
  default = "us-east-2"
}

variable "project_name" {
  type = string
  default = "project"
}

terraform {
    backend "s3" {
        bucket = var.backend_bucket_name
        key = var.backend_bucket_key
        region = var.region
    }
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.3.0"
      }
    }
}

provider "aws" {
    region = var.region
}

# IAM
resource "aws_iam_role" "cluster_role" {
  name = "${var.project_name}_cluster_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "$${var.project_name}_IAMFullAccess_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy_attachment" "$${var.project_name}_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy_attachment" "$${var.project_name}_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role" "node_role" {
  name = "${var.project_name}_node"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "$${var.project_name}_IAMFullAccess_node" {
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "$${var.project_name}_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "$${var.project_name}_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "$${var.project_name}_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

# VPC
resource "aws_vpc" "default" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "172.16.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public2"
  }
}

#EKS
resource "aws_eks_cluster" "k8s_cluster" {
  name = "${var.project_name}_eks_cluster"
  role_arn = aws_iam_role.cluster_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]
  }
}

resource "aws_eks_node_group" "k8s_node_group" {
  cluster_name    = aws_eks_cluster.k8s_cluster.name
  node_group_name = "${var.project_name}_eks_node_group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.public1.id, aws_subnet.public2.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
}


