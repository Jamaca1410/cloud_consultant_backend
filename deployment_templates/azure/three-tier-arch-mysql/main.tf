variable "client_id" {
  type        = string
  default     = ""
  description = "Azure Client ID"
}

variable "client_secret" {
  type        = string
  default     = ""
  description = "Azure Client Secret"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  default     = ""
  description = "Azure Tenant ID"
}

variable "subscription_id" {
  type        = string
  default     = ""
  description = "Azure Subscription ID"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.97.1"
    }
  }
}

provider "azurerm" {
  features {}
  client_id                  = var.client_id
  client_secret              = var.client_secret
  tenant_id                  = var.tenant_id
  subscription_id            = var.subscription_id
  skip_provider_registration = true
}

resource "azurerm_resource_group" "cc-rg-1" {
  name     = "cc-rg-1"
  location = "East US 2"
}

resource "azurerm_network_security_group" "cc-nsg-web" {
  name                = "cc-nsg-web"
  location            = azurerm_resource_group.cc-rg-1.location
  resource_group_name = azurerm_resource_group.cc-rg-1.name

  security_rule {
    name                       = "cc-nsg-web-allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "cc-vn-1"{
    name = "cc-vn-1"
    location = azurerm_resource_group.cc-rg-1.location
    resource_group_name = azurerm_resource_group.cc-rg-1.name
    address_space = ["10.16.0.0/16"]

    subnet {
        name = "cc-sn-web-a"
        address_prefix = "10.16.0.0/20"
    }

    subnet {
        name = "cc-sn-web-b"
        address_prefix = "10.16.16.0/20"
    }

    subnet {
        name = "cc-sn-app-a"
        address_prefix = "10.16.32.0/20"
    }

    subnet {
        name = "cc-sn-app-b"
        address_prefix = "10.16.48.0/20"
    }

    subnet {
        name = "cc-sn-db-a"
        address_prefix = "10.16.64.0/20"
    }

    subnet {
        name = "cc-sn-db-b"
        address_prefix = "10.16.80.0/20"
    }
}