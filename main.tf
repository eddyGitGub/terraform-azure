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
  location = "eastus"

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

resource "azurerm_subnet" "rgdev-subnet" {
  name                 = "rgdev-subnet"
  resource_group_name  = azurerm_resource_group.rgdev.name
  virtual_network_name = azurerm_virtual_network.rgdev-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "rgdev-sg" {
  name                = "rgdev-sg"
  location            = azurerm_resource_group.rgdev.location
  resource_group_name = azurerm_resource_group.rgdev.name

  tags = {
    Environment = "dev"
  }
}

resource "azurerm_network_security_rule" "rgdev-dev-rule" {

  name                        = "rgdev-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgdev.name
  network_security_group_name = azurerm_network_security_group.rgdev-sg.name

}

resource "azurerm_subnet_network_security_group_association" "rgdev-sga" {
  subnet_id                 = azurerm_subnet.rgdev-subnet.id
  network_security_group_id = azurerm_network_security_group.rgdev-sg.id
}

resource "azurerm_public_ip" "rgdev-ip" {
  name                = "rgdev-ip"
  resource_group_name = azurerm_resource_group.rgdev.name
  location            = azurerm_resource_group.rgdev.location
  allocation_method   = "Dynamic"

  tags = {
    Environment = "dev"
  }
}

resource "azurerm_network_interface" "rgdev-nic" {
  name                = "rgdev-nic"
  location            = azurerm_resource_group.rgdev.location
  resource_group_name = azurerm_resource_group.rgdev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rgdev-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rgdev-ip.id

  }
  tags = {
    Environment = "dev"
  }
}

# resource "azurerm_windows_virtual_machine" "rgdev-vm" {
#   name                = "rgdev-vm"
#   resource_group_name = azurerm_resource_group.rgdev.name
#   location            = azurerm_resource_group.rgdev.location
#   size                = "Standard_F1"
#   admin_username      = "adminuser"
#   admin_password      = "P@$$w0rd1234!"
#   network_interface_ids = [
#     azurerm_network_interface.rgdev-nic.id,
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2016-Datacenter"
#     version   = "latest"
#   }
# }

resource "azurerm_linux_virtual_machine" "rgdev-vm" {
  name                = "rgdev-vm"
  resource_group_name = azurerm_resource_group.rgdev.name
  location            = azurerm_resource_group.rgdev.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.rgdev-nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/rgdevazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}