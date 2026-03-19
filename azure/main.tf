terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.1.0"
    }
  }

}


provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  features {}
}


//Sahar
resource "azurerm_resource_group" "saharRg" {
  name     = "sahar-rg"
  location = "East US"
}

// Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.saharRg.name
  location            = azurerm_resource_group.saharRg.location
  sku                 = "Basic"
  admin_enabled       = true
}

// Get current Terraform operator identity (needed for Key Vault access policy)
data "azurerm_client_config" "current" {}

// Azure Key Vault — centralized secrets management for AKS workloads
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.saharRg.location
  resource_group_name = azurerm_resource_group.saharRg.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # Allow Terraform operator (current user) to manage secrets
  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Purge"]
  }

  # Allow AKS kubelet identity to read secrets via CSI driver
  access_policy {
    tenant_id = var.tenant_id
    object_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

    secret_permissions = ["Get", "List"]
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

// Store ACR credentials in Key Vault (no longer needed in plain env vars)
resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = var.acr_admin_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

// AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.saharRg.location
  resource_group_name = azurerm_resource_group.saharRg.name
  dns_prefix          = var.aks_dns_prefix
  kubernetes_version  = "1.32"

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable Azure Key Vault CSI Secrets Store driver
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = {
    Environment = "dev"
    Project     = "pfe-devops"
  }
}

// Attach ACR to AKS so the cluster can pull images
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true

  depends_on = [azurerm_kubernetes_cluster.aks]
}

// Outputs
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aks_kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

