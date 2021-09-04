# Azure Front Door Terraform Module

Azure Front Door is a fast, reliable, and secure modern cloud CDN that uses the Microsoft global edge network and integrates with intelligent threat protection. It combines the capabilities of Azure Front Door, Azure Content Delivery Network (CDN) standard, and Azure Web Application Firewall (WAF) into a single secure cloud CDN platform.

This Terraform module helps create Microsoft's highly available and scalable web application acceleration platform and global HTTP(s) load balancer Azure Front Door Service with Web Application Firewall policies and SSL offloading.

## Module Usage

```terraform
# Azurerm Provider configuration
provider "azurerm" {
  features {}
}

module "frontdoor" {
  source  = "kumarvna/frontdoor/azurerm"
  version = "1.0.0"

  # By default, this module will not create a resource group. Location will be same as existing RG.
  # proivde a name to use an existing resource group, specify the existing resource group name, 
  # set the argument to `create_resource_group = true` to create new resrouce group.
  resource_group_name = "rg-shared-westeurope-01"
  location            = "westeurope"
  frontdoor_name      = "example-frontdoor51"

  routing_rules = [
    {
      name               = "exampleRoutingRule1"
      accepted_protocols = ["Http", "Https"]
      patterns_to_match  = ["/*"]
      frontend_endpoints = ["exampleFrontendEndpoint1"]
      forwarding_configuration = {
        forwarding_protocol = "MatchRequest"
        backend_pool_name   = "exampleBackendBing"
      }
    }
  ]

  backend_pool_load_balancing = [
    {
      name = "exampleLoadBalancingSettings1"
    }
  ]

  backend_pool_health_probes = [
    {
      name = "exampleHealthProbeSetting1"
    }
  ]

  backend_pools = [
    {
      name = "exampleBackendBing"
      backend = {
        host_header = "www.bing.com"
        address     = "www.bing.com"
        http_port   = 80
        https_port  = 443
      }
      load_balancing_name = "exampleLoadBalancingSettings1"
      health_probe_name   = "exampleHealthProbeSetting1"
    }
  ]

  # In order to enable the use of your own custom HTTPS certificate you must grant  
  # Azure Front Door Service access to your key vault. For instuctions on how to  
  # configure your Key Vault correctly. Please refer to the product documentation.
  # https://bit.ly/38FuAZv

  frontend_endpoints = [
    {
      name      = "exampleFrontendEndpoint1"
      host_name = "example-frontdoor51.azurefd.net"
    },
    {
      name      = "exampleFrontendEndpoint2"
      host_name = "example-frontdoor52.azurefd.net"
      custom_https_configuration = {
        certificate_source = "FrontDoor"
      }
    },
    {
      name      = "exampleFrontendEndpoint3"
      host_name = "example-frontdoor53.azurefd.net"
      custom_https_configuration = {
        certificate_source                         = "AzureKeyVault"
        azure_key_vault_certificate_vault_id       = "" # valid keyvalut id
        azure_key_vault_certificate_secret_name    = "" # valid certificate secret
        azure_key_vault_certificate_secret_version = "Latest"
      }
    }
  ]

  # (Optional) To enable Azure Monitoring for Azure Frontdoor
  # (Optional) Specify `storage_account_name` to save monitoring logs to storage. 
  log_analytics_workspace_name = "loganalytics-we-sharedtest2"

  # Adding TAG's to your Azure resources 
  tags = {
    ProjectName  = "demo-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}
```

## Module Usage examples for

* [Frontdoor with SSL Offloading](examples/frontdoor_with_custom_https_configuration/)
* [Frontdoor with WAF Policies](examples/frontdoor_with_waf_policies/)

## **`backend_pools`** - Backends and backend pools

A backend pool in Front Door refers to the set of backends that receive similar traffic for their app. In other words, A logical grouping of app instances across the world that receive the same traffic and respond with expected behavior. These backends are deployed across different regions or within the same region. All backends can be in `Active/Active` deployment mode or what is defined as `Active/Passive` configuration. Azure by default allows specifying up to `50` Backend Pools.

Front Door backends refers to the host name or public IP of your application that serves your client requests. Front Door supports both Azure and non-Azure resources in the backend pool. The application can either be in your on-premises datacenter or located in another cloud provider.

`backend_pools` object accepts following argumnets

| Name | Description
|--|--
`name`| Specifies the name of the Backend Pool
`load_balancing_name`|Specifies the name of the `backend_pool_load_balancing` block within this resource to use for this `Backend Pool`.
`health_probe_name`|Specifies the name of the `backend_pool_health_probe` block within this resource to use for this `Backend Pool`.
`backend` |  A backend block as defined below.

> `backend` - A backend block as defined below

| Name | Description
|--|--
`address`|Location of the backend (IP address or FQDN)
`host_header`|The value to use as the host header sent to the backend.
`http_port`|The HTTP TCP port number. Possible values are between `1` - `65535`.
`https_port`|The HTTPS TCP port number. Possible values are between `1` - `65535`.
`priority`| Priority to use for load balancing. Higher priorities will not be used for load balancing if any lower priority backend is healthy. Defaults to `1`.
`weight`| Weight of this endpoint for load balancing purposes. Defaults to `50`.

## **`backend_pool_health_probes`** - Health probes

To determine the health and proximity of each backend for a given Front Door environment, each Front Door environment periodically sends a synthetic HTTP/HTTPS request to each of your configured backends. Front Door then uses these responses from the probe to determine the "best" backend resources to route your client requests.

> For lower load and cost on your backends, Front Door recommends using `HEAD` requests for health probes.

`backend_pool_health_probes` object accepts following argumnets

| Name | Description
|--|--
`name`|Specifies the name of the Health Probe.
`enabled`|Is this health probe enabled? Dafaults to `true`.
`path`|The path to use for the Health Probe. Default is `/`.
`protocol`|Protocol scheme to use for the Health Probe. Defaults to `Http`.
`probe_method`|Specifies HTTP method the health probe uses when querying the backend pool instances. Possible values include: `Get` and `Head`. Defaults to `Get`.
`interval_in_seconds`| The number of seconds between each Health Probe. Defaults to `120`.

## **`backend_pool_load_balancing`** - Load-balancing settings for the backend pool

Load-balancing settings for the backend pool define how we evaluate health probes. These settings determine if the backend is healthy or unhealthy. They also check how to load-balance traffic between different backends in the backend pool. The following settings are available for `backend_pool_load_balancing` object:

| Name | Description
|--|--
`name`|Specifies the name of the Load Balancer.
`sample_size`|The number of samples to consider for load balancing decisions. Defaults to `4`.
`successful_samples_required`|The number of samples within the sample period that must succeed. Defaults to `2`.
`additional_latency_milliseconds`|The additional latency in milliseconds for probes to fall into the lowest latency bucket. Defaults to `0`.

## **`frontend_endpoints`** - Add a custom domain to your Front Door

The frontend host specifies a desired subdomain on Front Door's default domain i.e. azurefd.net to route traffic from that host via Front Door. You can optionally onboard custom domains as well.

Before you can use a custom domain with your Front Door, you must first create a canonical name (CNAME) record with your domain provider to point to your Front Door's default frontend host (say contoso.azurefd.net). A custom domain and its subdomain can be associated with only a single Front Door at a time. The following settings are available for `frontend_endpoints` object:

| Name | Description
|--|--
`name`|Specifies the name of the frontend_endpoint.
`host_name`|Specifies the host name of the frontend_endpoint. Must be a domain name. In order to use a `name.azurefd.net` domain, the name value must match the Front Door name.
`session_affinity_enabled`|Whether to allow session affinity on this host. Valid options are true or false Defaults to false.
`session_affinity_ttl_seconds`|The TTL to use in seconds for session affinity, if applicable. Defaults to 0.
`web_application_firewall_policy_link_id`|Defines the Web Application Firewall policy ID for each host. By default pickup existing WAF policy if specified with module.
`custom_https_configuration` | The `custom_https_configuration` block supports the following

> The `custom_https_configuration`- block supports the following

| Name | Description
|--|--
`certificate_source`|Certificate source to encrypted `HTTPS` traffic with. Allowed values are `FrontDoor` or `AzureKeyVault`. Defaults to `FrontDoor`.
`azure_key_vault_certificate_vault_id`|The ID of the Key Vault containing the SSL certificate. Only valid if `certificate_source` is set to `AzureKeyVault`
`azure_key_vault_certificate_secret_name`|The name of the Key Vault secret representing the full certificate PFX. Only valid if `certificate_source` is set to `AzureKeyVault`
`azure_key_vault_certificate_secret_version`|The version of the Key Vault secret representing the full certificate PFX. Defaults to Latest. Only valid if `certificate_source` is set to `AzureKeyVault`

## **`routing_rules`** - How requests are matched to a routing rule

After establishing a connection and completing a TLS handshake, when a request lands on a Front Door environment one of the first things that Front Door does is determine which particular routing rule to match the request to and then take the defined action in the configuration.

A Front Door routing rule configuration is composed of two major parts: a "left-hand side" and a "right-hand side". We match the incoming request to the left-hand side of the route while the right-hand side defines how we process the request. The following settings are available for `routing_rules` object:

| Name | Description
|--|--
`name`|Specifies the name of the Routing Rule.
`frontend_endpoints`|The names of the `frontend_endpoint` blocks within this resource to associate with this `routing_rule`.
`accepted_protocols`|Protocol schemes to match for the Backend Routing Rule. Defaults to `Http`.
`patterns_to_match`| The route patterns for the Backend Routing Rule. Defaults to `/*`.

> `forwarding_configuration`| A forwarding_configuration block as defined below

| Name | Description
|--|--
`backend_pool_name`|Specifies the name of the Backend Pool to forward the incoming traffic to.
`cache_enabled`|Specifies whether to Enable caching or not. Valid options are `true` or `false`. Defaults to `false`.
`cache_use_dynamic_compression`|Whether to use dynamic compression when caching. Valid options are `true` or `false`. Defaults to `false`.
`cache_query_parameter_strip_directive`|Defines cache behaviour in relation to query string parameters. Valid options are `StripAll`, `StripAllExcept`, `StripOnly` or `StripNone`. Defaults to `StripAll`.
`cache_query_parameters`|Specify query parameters (array). Works only in combination with `cache_query_parameter_strip_directive` set to `StripAllExcept` or `StripOnly`.
`cache_duration`|Specify the caching duration (in ISO8601 notation e.g. `P1DT2H` for 1 day and 2 hours). Needs to be greater than 0 and smaller than 365 days. `cache_duration` works only in combination with `cache_enabled` set to `true`.
`custom_forwarding_path`|Path to use when constructing the request to forward to the backend. This functions as a URL Rewrite. Default behaviour preserves the URL path.
forwarding_protocol | Protocol to use when redirecting. Valid options are `HttpOnly`, `HttpsOnly`, or `MatchRequest`. Defaults to `HttpsOnly`.

> `redirect_configuration`| A redirect_configuration block as defined below

| Name | Description
|--|--
`custom_host`|Set this to change the URL for the redirection.
`redirect_protocol`|Protocol to use when redirecting. Valid options are `HttpOnly`, `HttpsOnly`, or `MatchRequest`. Defaults to `MatchRequest`
`redirect_type`|Status code for the redirect. Valida options are `Moved`, `Found`, `TemporaryRedirect`, `PermanentRedirect`.
`custom_fragment`|The destination fragment in the portion of URL after '#'. Set this to add a fragment to the redirect URL.
`custom_path`|The path to retain as per the incoming request, or update in the URL for the redirection.
`custom_query_string`|Replace any existing query string from the incoming request URL.

## Recommended naming and tagging conventions

Applying tags to your Azure resources, resource groups, and subscriptions to logically organize them into a taxonomy. Each tag consists of a name and a value pair. For example, you can apply the name `Environment` and the value `Production` to all the resources in production.
For recommendations on how to implement a tagging strategy, see Resource naming and tagging decision guide.

>**Important** :
Tag names are case-insensitive for operations. A tag with a tag name, regardless of the casing, is updated or retrieved. However, the resource provider might keep the casing you provide for the tag name. You'll see that casing in cost reports. **Tag values are case-sensitive.**

An effective naming convention assembles resource names by using important resource information as parts of a resource's name. For example, using these [recommended naming conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging#example-names), a public IP resource for a production SharePoint workload is named like this: `pip-sharepoint-prod-westus-001`.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| azurerm | >= 2.59.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 2.59.0 |

## Inputs

Name | Description | Type | Default
---- | ----------- | ---- | -------
`create_resource_group`|Create new resource group and use it for all networking resources|string|`""`
`resource_group_name`|The name of an existing resource group.|string|`""`
`location`|The location for all resources while creating a new resource group.|string|`""`
`frontdoor_name`|Specifies the name of the Front Door service. Must be globally unique|string|`""`
friendly_name|A friendly name for the Front Door service|string|`""`
`backend_pools_send_receive_timeout_seconds`|Specifies the send and receive timeout on forwarding request to the backend. When the timeout is reached, the request fails and returns. Possible values are between `0` - `240`. Defaults to `60`.|number|`60`
string|`""`
`enforce_backend_pools_certificate_name_check`|Enforce certificate name check on HTTPS requests to all backend pools, this setting will have no effect on HTTP requests. Permitted values are `true` or `false`.|string|`false`
`backend_pools`|A logical grouping of app instances across the world that receive the same traffic and respond with expected behavior. These backends are deployed across different regions or within the same region. All backends can be in `Active/Active` deployment mode or what is defined as `Active/Passive` configuration. Azure by default allows specifying up to `50` Backend Pools.|list(object({}))|`[]`
`backend_pool_health_probes`|The list of backend pool health probes.|list(object({}))|`[]`
`backend_pool_load_balancing`|Load-balancing settings for the backend pool to determine if the backend is healthy or unhealthy. They also check how to load-balance traffic between different backends in the backend pool.|list(object({}))|`[]`
`frontend_endpoints`|Lists all of the frontend endpoints within a Front Door|list(object({}))|`[]`
`routing_rules`|The list of Routing Rules to determine which particular rule to match the request to and then take the defined action in the configuration|list(object({}))|`[]`
web_application_firewall_policy|Manages an Azure Front Door Web Application Firewall Policy instance|map(object({}))|`null`
`log_analytics_workspace_name`|The name of log analytics workspace name|string|`null`
`storage_account_name`|The name of the hub storage account to store logs|string|`null`
`Tags`|A map of tags to add to all resources|map|`{}`

## Outputs

Name | Description
---- | -----------
`resource_group_name`| The name of the resource group in which resources are created
`resource_group_id`| The id of the resource group in which resources are created
`resource_group_location`| The location of the resource group in which resources are created
`backend_pool_ids`|The ID's of the Azure Front Door Backend Pool
`backend_pool_health_probes`|The ID's of the Azure Front Door Backend Health Probe
`backend_pool_load_balancing`|The ID of the Azure Front Door Backend Load Balancer
`frontend_endpoint_id`|The ID of the Azure Front Door Frontend Endpoint
`frontdoor_id`|The ID of the FrontDoor
`frontdoor_waf_policy_id`|The ID of the FrontDoor Firewall Policy
`frontdoor_waf_policy_location`|The Azure Region where this FrontDoor Firewall Policy exists
`frontdoor_waf_policy_frontend_endpoint_ids`|The Frontend Endpoints associated with this Front Door Web Application Firewall policy

## Resource Graph

![](graph.png)

## Authors

Originally created by [Kumaraswamy Vithanala](mailto:kumarvna@gmail.com)

## Other resources

* [Azure Frontdoor documentation](https://docs.microsoft.com/en-us/azure/frontdoor/front-door-overview)

* [Terraform AzureRM Provider Documentation](https://www.terraform.io/docs/providers/azurerm/index.html)
