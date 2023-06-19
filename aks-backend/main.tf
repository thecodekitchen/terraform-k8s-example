variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "backend_rg_name" {
    type = string
    default = "tf-state-resources"
}

variable "backend_sa_name" {
    type = string
    default = "tf-state-storage-account"
}

variable "backend_bucket_name" {
    type = string
    default = "tf-state-bucket"
}

resource "azurerm_resource_group" "backend_rg" {
  name     = var.backend_rg_name
  location = var.resource_group_location
}

resource "azurerm_storage_account" "backend_sa" {
  name                     = var.backend_sa_name
  resource_group_name      = azurerm_resource_group.backend_rg.name
  location                 = azurerm_resource_group.backend_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "backend_bucket" {
  name                  = var.backend_bucket_name
  storage_account_name  = azurerm_storage_account.backend_sa.name
  container_access_type = "private"
}

