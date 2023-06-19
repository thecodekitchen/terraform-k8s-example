terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.3.0"
      }
    }
}

variable "region" {
    type = string
    default = "us-east-2"
}

variable "bucket_name" {
    type = string
    default = "tf-state-bucket"
}

provider "aws" {
    region = var.region
}

resource "aws_s3_bucket" "remote_backend" {
  bucket = var.bucket_name
  tags = {
    Name        = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "remote_backend_versioning" {
  bucket = aws_s3_bucket.remote_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}
