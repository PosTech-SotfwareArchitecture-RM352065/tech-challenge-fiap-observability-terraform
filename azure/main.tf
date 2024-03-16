terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
  backend "azurerm" {
    key = "terraform-observability.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "observability_group" {
  name     = "fiap-tech-challenge-observability-group"
  location = "eastus"

  tags = {
    environment = "development"
  }
}

resource "azurerm_storage_account" "log_storage_account" {
  name                     = "sandubalog"
  resource_group_name      = azurerm_resource_group.observability_group.name
  location                 = azurerm_resource_group.observability_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = azurerm_resource_group.observability_group.tags["environment"]
  }
}

resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "fiap-tech-challenge-observability"
  location            = azurerm_resource_group.observability_group.location
  resource_group_name = azurerm_resource_group.observability_group.name
  sku                 = "PerGB2018"

  tags = {
    environment = azurerm_resource_group.observability_group.tags["environment"]
  }
}

resource "azurerm_log_analytics_solution" "log_solution_container_insights" {
  solution_name         = "fiap-tech-challenge-container-insights"
  location              = azurerm_log_analytics_workspace.log_workspace.location
  resource_group_name   = azurerm_resource_group.observability_group.name
  workspace_resource_id = azurerm_log_analytics_workspace.log_workspace.id
  workspace_name        = azurerm_log_analytics_workspace.log_workspace.name

  plan {
    publisher = "Microsoft"
    product   = "ContainerInsights"
  }

  tags = {
    environment = azurerm_resource_group.observability_group.tags["environment"]
  }
}

data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "subscription_monitor" {
  name                       = "fiap-tech-challenge-subscription-monitor"
  target_resource_id         = data.azurerm_subscription.current.id
  storage_account_id         = azurerm_storage_account.log_storage_account.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }

  metric {
    category = "AllMetrics"
  }
}
