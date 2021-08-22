variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = false
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "frontdoor_name" {
  description = "Specifies the name of the Front Door service. Must be globally unique."
  default     = ""
}

variable "friendly_name" {
  description = "A friendly name for the Front Door service."
  default     = ""
}

variable "backend_pools_send_receive_timeout_seconds" {
  description = "Specifies the send and receive timeout on forwarding request to the backend. When the timeout is reached, the request fails and returns. Possible values are between `0` - `240`. Defaults to `60`."
  default     = 60
}

variable "enforce_backend_pools_certificate_name_check" {
  description = "Enforce certificate name check on HTTPS requests to all backend pools, this setting will have no effect on HTTP requests. Permitted values are `true` or `false`."
  default     = false
}

variable "backend_pool" {
  description = "A logical grouping of app instances across the world that receive the same traffic and respond with expected behavior. These backends are deployed across different regions or within the same region. All backends can be in `Active/Active` deployment mode or what is defined as `Active/Passive` configuration. Azure by default allows specifying up to `50` Backend Pools."
  type = list(object({
    name = string
    backend = object({
      address     = string
      host_header = string
      http_port   = number
      https_port  = number
      priority    = optional(number)
      weight      = optional(number)
    })
    load_balancing_name = string
    health_probe_name   = string
  }))
  default = []
}


variable "backend_pool_health_probe" {
  description = "The list of backend pool health probes."
  type = list(object({
    name                = string
    path                = optional(string)
    protocol            = optional(string)
    probe_method        = optional(string)
    interval_in_seconds = optional(number)
  }))
  default = []
}

variable "backend_pool_load_balancing" {
  description = "Load-balancing settings for the backend pool to determine if the backend is healthy or unhealthy. They also check how to load-balance traffic between different backends in the backend pool."
  type = list(object({
    name                            = string
    sample_size                     = optional(number)
    successful_samples_required     = optional(number)
    additional_latency_milliseconds = optional(number)
  }))
  default = []
}

variable "frontend_endpoint" {
  description = "Lists all of the frontend endpoints within a Front Door"
  type = list(object({
    name                                    = string
    host_name                               = string
    session_affinity_enabled                = optional(bool)
    session_affinity_ttl_seconds            = optional(number)
    web_application_firewall_policy_link_id = optional(string)
  }))
  default = []
}

variable "routing_rule" {
  description = "The list of Routing Rules to determine which particular rule to match the request to and then take the defined action in the configuration"
  type = list(object({
    name               = string
    frontend_endpoints = list(string)
    accepted_protocols = optional(list(string))
    patterns_to_match  = optional(list(string))
    forwarding_configuration = optional(object({
      backend_pool_name                     = string
      cache_enabled                         = optional(bool)
      cache_use_dynamic_compression         = optional(bool)
      cache_query_parameter_strip_directive = optional(string)
      cache_query_parameters                = optional(list(string))
      cache_duration                        = optional(string)
      custom_forwarding_path                = optional(string)
      forwarding_protocol                   = optional(string)
    }))
    redirect_configuration = optional(object({
      custom_host         = optional(string)
      redirect_protocol   = optional(string)
      redirect_type       = string
      custom_fragment     = optional(string)
      custom_path         = optional(string)
      custom_query_string = optional(string)
    }))
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
