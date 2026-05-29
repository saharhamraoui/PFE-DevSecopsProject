variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "acr_name" {
  type        = string
  description = "Name of the Azure Container Registry (must be globally unique, alphanumeric only)"
  default     = "saharacr"
}

variable "aks_cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
  default     = "sahar-aks"
}

variable "aks_dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster"
  default     = "saharaks"
}

variable "aks_node_count" {
  type        = number
  description = "Number of nodes in the AKS default node pool"
  default     = 1
}

variable "key_vault_name" {
  type        = string
  description = "Name of the Azure Key Vault (globally unique, 3-24 alphanumeric chars)"
  default     = "sahar-kv-pfe"
}

variable "acr_admin_password" {
  type        = string
  description = "ACR admin password — stored in Key Vault (sensitive)"
  sensitive   = true
  default     = ""
}