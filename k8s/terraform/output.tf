output "resource_group_name" {
    value = azurerm_resource_group.rg.name
}

output "k8s_cluster_name" {
    value = azurerm_kubernetes_cluster.aks_cluster.name
}