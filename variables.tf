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
    backup = object({
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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
