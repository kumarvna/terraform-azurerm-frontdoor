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
  backend_pools_send_receive_timeout_seconds   = var.backend_pools_send_receive_timeout_seconds
  enforce_backend_pools_certificate_name_check = var.enforce_backend_pools_certificate_name_check
  load_balancer_enabled                        = true
  friendly_name                                = var.friendly_name
  tags                                         = merge({ "ResourceName" = format("%s", var.frontdoor_name) }, var.tags, )

  dynamic "backend_pool" {
    for_each = var.backend_pools
    content {
      name                = backend_pool.value.name
      load_balancing_name = backend_pool.value.load_balancing_name
      health_probe_name   = backend_pool.value.health_probe_name

      dynamic "backend" {
        for_each = backend_pool.value.backend[*]
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
    for_each = var.backend_pool_health_probes
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
    for_each = var.frontend_endpoints
    content {
      name                                    = frontend_endpoint.value.name
      host_name                               = frontend_endpoint.value.host_name
      session_affinity_enabled                = frontend_endpoint.value.session_affinity_enabled
      session_affinity_ttl_seconds            = frontend_endpoint.value.session_affinity_ttl_seconds
      web_application_firewall_policy_link_id = var.web_application_firewall_policy != null && frontend_endpoint.value.web_application_firewall_policy_link_id == null ? azurerm_frontdoor_firewall_policy.main.0.id : frontend_endpoint.value.web_application_firewall_policy_link_id
    }
  }

  dynamic "routing_rule" {
    for_each = var.routing_rules
    content {
      name               = routing_rule.value.name
      frontend_endpoints = routing_rule.value.frontend_endpoints
      accepted_protocols = routing_rule.value.accepted_protocols
      patterns_to_match  = routing_rule.value.patterns_to_match
      enabled            = true

      dynamic "forwarding_configuration" {
        for_each = routing_rule.value.forwarding_configuration[*]
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
        for_each = routing_rule.value.redirect_configuration[*]
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

#-------------------------------------------------------------------------
# Frontdoor Web application Firewall Policy Creation - Default is "false"
#-------------------------------------------------------------------------
resource "azurerm_frontdoor_firewall_policy" "main" {
  count                             = var.web_application_firewall_policy != null ? 1 : 0
  name                              = format("%s", var.web_application_firewall_policy.name)
  resource_group_name               = local.resource_group_name
  enabled                           = true
  mode                              = lookup(var.web_application_firewall_policy, "mode", "Prevention")
  redirect_url                      = var.web_application_firewall_policy.redirect_url
  custom_block_response_status_code = var.web_application_firewall_policy.custom_block_response_status_code
  custom_block_response_body        = var.web_application_firewall_policy.custom_block_response_body
  tags                              = merge({ "ResourceName" = format("%s", var.web_application_firewall_policy.name) }, var.tags, )

  dynamic "custom_rule" {
    for_each = var.web_application_firewall_policy.custom_rule
    content {
      name                           = format("%s", custom_rule.value.name)
      action                         = custom_rule.value.action
      enabled                        = true
      priority                       = custom_rule.value.priority
      type                           = custom_rule.value.type
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold

      dynamic "match_condition" {
        for_each = [custom_rule.value.match_condition]
        content {
          match_variable     = match_condition.value.match_variable
          match_values       = match_condition.value.match_values
          operator           = match_condition.value.operator
          selector           = match_condition.value.selector
          negation_condition = match_condition.value.negation_condition
          transforms         = match_condition.value.transforms
        }
      }
    }
  }

  dynamic "managed_rule" {
    for_each = var.web_application_firewall_policy.managed_rule
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version

      dynamic "exclusion" {
        for_each = managed_rule.value.exclusion
        content {
          match_variable = exclusion.value.match_variable
          operator       = exclusion.value.operator
          selector       = exclusion.value.selector
        }
      }

      dynamic "override" {
        for_each = managed_rule.value.override
        content {
          rule_group_name = override.value.rule_group_name

          dynamic "exclusion" {
            for_each = override.value.exclusion
            content {
              match_variable = exclusion.value.match_variable
              operator       = exclusion.value.operator
              selector       = exclusion.value.selector
            }
          }

          dynamic "rule" {
            for_each = override.value.rule
            content {
              rule_id = rule.value.rule_id
              action  = rule.value.action
              enabled = lookup(rule.value, "enabled", false)
              dynamic "exclusion" {
                for_each = rule.value.exclusion
                content {
                  match_variable = exclusion.value.match_variable
                  operator       = exclusion.value.operator
                  selector       = exclusion.value.selector
                }
              }
            }
          }
        }
      }
    }
  }
}

#-------------------------------------------------------------------------
# Custom Https Configuration for an Azure Front Door Frontend Endpoint
#-------------------------------------------------------------------------
resource "azurerm_frontdoor_custom_https_configuration" "main" {
  for_each                          = { for fe in var.frontend_endpoints : fe.name => fe if try(fe["custom_https_configuration"], null) != null }
  frontend_endpoint_id              = format("%s/frontendEndpoints/%s", azurerm_frontdoor.main.id, each.key)
  custom_https_provisioning_enabled = true

  custom_https_configuration {
    certificate_source                         = try(each.value["custom_https_configuration"]["certificate_source"], "FrontDoor")
    azure_key_vault_certificate_vault_id       = try(each.value["custom_https_configuration"]["azure_key_vault_certificate_vault_id"], null)
    azure_key_vault_certificate_secret_name    = try(each.value["custom_https_configuration"]["azure_key_vault_certificate_secret_name"], null)
    azure_key_vault_certificate_secret_version = try(each.value["custom_https_configuration"]["azure_key_vault_certificate_secret_version"], null)
  }
}
