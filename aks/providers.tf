terraform {
  required_version = ">=1.0"

  backend "azurerm" {
    resource_group_name  = "rg-bardchat-tf"
    storage_account_name = "sabardchattf"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
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
