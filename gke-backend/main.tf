variable "backend_bucket_name" {
  type = string
  default = "tf-state-backend"
}

variable "gcp_project_name" {
    type = string
}

variable "gcp_project_region" {
    type = string
    default = "us-central1"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.27.0"
    }
  }
  required_version = ">= 0.14"
}

provider "google" {
    project = var.gcp_project_name
    region = var.gcp_project_region
}

resource "google_storage_bucket" "remote_backend" {
  name          = var.backend_bucket_name
  location      = "US"
  force_destroy = true
  public_access_prevention = "enforced"
}