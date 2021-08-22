#---------------------------------
# Local declarations
#---------------------------------
locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
}

#---------------------------------------------------------
# Resource Group Creation or selection - Default is "true"
#----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = lower(var.resource_group_name)
  location = var.location
  tags     = merge({ "ResourceName" = format("%s", var.resource_group_name) }, var.tags, )
}

#---------------------------------------------------------
# Frontdoor Resource Creation - Default is "true"
#----------------------------------------------------------
resource "azurerm_frontdoor" "main" {
  name                                         = format("%s", var.frontdoor_name)
  resource_group_name                          = local.resource_group_name
  location                                     = local.location
  backend_pools_send_receive_timeout_seconds   = var.backend_pools_send_receive_timeout_seconds
  enforce_backend_pools_certificate_name_check = var.enforce_backend_pools_certificate_name_check
  load_balancer_enabled                        = true
  friendly_name                                = var.friendly_name
  tags                                         = merge({ "ResourceName" = format("%s", var.frontdoor_name) }, var.tags, )

  dynamic "backend_pool" {
    for_each = var.backend_pool
    content {
      name                = backend_pool.value.name
      load_balancing_name = backend_pool.value.load_balancing_name
      health_probe_name   = backend_pool.value.health_probe_name
      dynamic "backend" {
        for_each = backend_pool.value.backend
        content {
          enabled     = true
          address     = backend.value.address
          host_header = backend.value.host_header
          http_port   = backend.value.http_port
          https_port  = backend.value.https_port
          priority    = backend.value.priority
          weight      = backend.value.weight
        }
      }
    }
  }

  dynamic "backend_pool_health_probe" {
    for_each = var.backend_pool_health_probe
    content {
      name                = backend_pool_health_probe.value.name
      enabled             = true
      path                = backend_pool_health_probe.value.path
      protocol            = backend_pool_health_probe.value.protocol
      probe_method        = backend_pool_health_probe.value.probe_method
      interval_in_seconds = backend_pool_health_probe.value.interval_in_seconds
    }
  }

  dynamic "backend_pool_load_balancing" {
    for_each = var.backend_pool_load_balancing
    content {
      name                            = backend_pool_load_balancing.value.name
      sample_size                     = backend_pool_load_balancing.value.sample_size
      successful_samples_required     = backend_pool_load_balancing.value.successful_samples_required
      additional_latency_milliseconds = backend_pool_load_balancing.value.additional_latency_milliseconds
    }
  }

  dynamic "frontend_endpoint" {
    for_each = var.frontend_endpoint
    content {
      name                                    = frontend_endpoint.value.name
      host_name                               = frontend_endpoint.value.host_name
      session_affinity_enabled                = frontend_endpoint.value.session_affinity_enabled
      session_affinity_ttl_seconds            = frontend_endpoint.value.session_affinity_ttl_seconds
      web_application_firewall_policy_link_id = frontend_endpoint.value.web_application_firewall_policy_link_id
    }
  }

  dynamic "routing_rule" {
    for_each = var.routing_rule
    content {
      name               = routing_rule.value.name
      frontend_endpoints = routing_rule.value.frontend_endpoints
      accepted_protocols = routing_rule.value.accepted_protocols
      patterns_to_match  = routing_rule.value.patterns_to_match
      enabled            = true
      dynamic "forwarding_configuration" {
        for_each = routing_rule.value.forwarding_configuration
        content {
          backend_pool_name                     = forwarding_configuration.value.backend_pool_name
          cache_enabled                         = lookup(forwarding_configuration.value, "cache_enabled", false)
          cache_use_dynamic_compression         = lookup(forwarding_configuration.value, "cache_use_dynamic_compression", false)
          cache_query_parameter_strip_directive = lookup(forwarding_configuration.value, "cache_query_parameter_strip_directive", "StripAll")
          cache_query_parameters                = forwarding_configuration.value.cache_query_parameters
          cache_duration                        = forwarding_configuration.value.cache_enabled == true ? forwarding_configuration.value.cache_duration : null
          custom_forwarding_path                = forwarding_configuration.value.custom_forwarding_path
          forwarding_protocol                   = forwarding_configuration.value.forwarding_protocol
        }
      }
      dynamic "redirect_configuration" {
        for_each = routing_rule.value.redirect_configuration
        content {
          custom_host         = redirect_configuration.value.custom_host
          redirect_protocol   = lookup(redirect_configuration.value, "redirect_protocol", "MatchRequest")
          redirect_type       = redirect_configuration.value.redirect_type
          custom_fragment     = redirect_configuration.value.custom_fragment
          custom_path         = redirect_configuration.value.custom_path
          custom_query_string = redirect_configuration.value.custom_query_string
        }
      }
    }
  }
}
