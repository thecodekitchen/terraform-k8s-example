provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-bardchat-tf"
    storage_account_name = "sabardchattf"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "rg-bardchat" {
  name     = "rg-bardchat"
  location = "northcentralus"
}

resource "azurerm_virtual_network" "vn-bardchat" {
  name                = "${var.prefix}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-bardchat.location
  resource_group_name = azurerm_resource_group.rg-bardchat.name
}

resource "azurerm_subnet" "sn-bardchat" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg-bardchat.name
  virtual_network_name = azurerm_virtual_network.vn-bardchat.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pi-bardchat" {
  name                = "${var.prefix}-pi"
  location            = azurerm_resource_group.rg-bardchat.location
  resource_group_name = azurerm_resource_group.rg-bardchat.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "ni-bardchat" {
  name                = "${var.prefix}-ni"
  location            = azurerm_resource_group.rg-bardchat.location
  resource_group_name = azurerm_resource_group.rg-bardchat.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn-bardchat.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pi-bardchat.id
  }
}

resource "azurerm_network_security_group" "sg-bardchat" {
  name                = "${var.prefix}NetworkSecurityGroup"
  location            = azurerm_resource_group.rg-bardchat.location
  resource_group_name = azurerm_resource_group.rg-bardchat.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "sga-bardchat" {
  network_interface_id      = azurerm_network_interface.ni-bardchat.id
  network_security_group_id = azurerm_network_security_group.sg-bardchat.id
}

resource "azurerm_linux_virtual_machine" "pvm-bardchat" {
  name                            = "${var.prefix}-lvm"
  resource_group_name             = azurerm_resource_group.rg-bardchat.name
  location                        = azurerm_resource_group.rg-bardchat.location
  size                            = "Standard_F2"
  admin_username                  = var.user_name
  admin_password                  = var.password
  provision_vm_agent              = false
  allow_extension_operations      = false
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.ni-bardchat.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


resource "azurerm_arc_kubernetes_cluster" "akc-bardchat" {
  name                         = "${var.prefix}-akc"
  resource_group_name          = azurerm_resource_group.rg-bardchat.name
  location                     = azurerm_resource_group.rg-bardchat.location
  agent_public_key_certificate = var.public_key
  identity {
    type = "SystemAssigned"
  }


  connection {
    type     = "ssh"
    host     = azurerm_public_ip.pi-bardchat.ip_address
    user     = var.user_name
    password = var.password
  }

  provisioner "file" {
    content = templatefile("testdata/install_agent.sh.tftpl", {
      subscription_id     = data.azurerm_subscription.current.subscription_id
      resource_group_name = azurerm_resource_group.rg-bardchat.name
      cluster_name        = azurerm_arc_kubernetes_cluster.akc-bardchat.name
      location            = azurerm_resource_group.rg-bardchat.location
      tenant_id           = data.azurerm_client_config.current.tenant_id
      working_dir         = "/home/${var.user_name}"
    })
    destination = "/home/${var.user_name}/install_agent.sh"
  }

  provisioner "file" {
    source      = "testdata/install_agent.py"
    destination = "/home/${var.user_name}/install_agent.py"
  }

  provisioner "file" {
    source      = "testdata/kind.yaml"
    destination = "/home/${var.user_name}/kind.yaml"
  }

  provisioner "file" {
    content     = var.private_pem
    destination = "/home/${var.user_name}/private.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/\r$//' /home/${var.user_name}/install_agent.sh",
      "sudo chmod +x /home/${var.user_name}/install_agent.sh",
      "bash /home/${var.user_name}/install_agent.sh > /home/${var.user_name}/agent_log",
    ]
  }


  depends_on = [
    azurerm_linux_virtual_machine.pvm-bardchat
  ]
}