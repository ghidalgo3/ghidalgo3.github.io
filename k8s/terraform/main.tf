resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.prefix}-aks-cluster"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.prefix}aks"
  network_profile {
    network_plugin = "azure"
    dns_service_ip = "192.168.255.254"
    service_cidrs  = ["192.168.0.0/16"]
  }

  default_node_pool {
    name           = "default"
    node_count     = 1
    vnet_subnet_id = data.azurerm_subnet.node_subnet.id
    vm_size        = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
}