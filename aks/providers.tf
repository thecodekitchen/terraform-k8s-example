terraform {
  required_version = ">=1.0"

  backend "azurerm" {
    resource_group_name  = var.backend_rg_name
    storage_account_name = var.backend_sa_name
    container_name       = var.backend_bucket_name
    key                  = var.backend_bucket_key
  }
  
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
  }
}

provider "azurerm" {
  features {}
}
