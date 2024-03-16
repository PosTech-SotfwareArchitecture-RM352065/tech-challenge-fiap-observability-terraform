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