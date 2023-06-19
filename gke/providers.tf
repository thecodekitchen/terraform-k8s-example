# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
variable "backend_bucket_name" {
  type = string
  default = "tf-state-backend"
}

terraform {
  backend "gcs" {
    bucket = var.backend_bucket_name
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.27.0"
    }
  }

  required_version = ">= 0.14"
}

