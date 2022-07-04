# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rgdev" {
  name     = "rgdev-resources"
  location = "westus2"

  tags = {
    Environment = "dev"
    #Team = "DevOps"
  }
}
resource "azurerm_virtual_network" "rgdev-vn" {
  name                = "rgdev-network"
  resource_group_name = azurerm_resource_group.rgdev.name
  location            = azurerm_resource_group.rgdev.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    Environment = "dev"
  }
}