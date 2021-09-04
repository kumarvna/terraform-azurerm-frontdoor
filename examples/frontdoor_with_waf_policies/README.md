# Azure Front Door Terraform Module

Azure Front Door Standard/Premium is a fast, reliable, and secure modern cloud CDN that uses the Microsoft global edge network and integrates with intelligent threat protection. It combines the capabilities of Azure Front Door, Azure Content Delivery Network (CDN) standard, and Azure Web Application Firewall (WAF) into a single secure cloud CDN platform.

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

  # In order to enable the use of your own custom HTTPS certificate you must grant Azure Front Door Service 
  # access to your key vault. For instuctions on how to configure your Key Vault correctly 
  # Please refer to the product documentation (https://bit.ly/38FuAZv).
  frontend_endpoints = [
    {
      name      = "exampleFrontendEndpoint1"
      host_name = "kumars-frontdoor21.azurefd.net"
    },
    {
      name      = "exampleFrontendEndpoint2"
      host_name = "kumars-frontdoor22.azurefd.net"
      custom_https_configuration = {
        certificate_source = "FrontDoor"
      }
    },
    {
      name      = "exampleFrontendEndpoint3"
      host_name = "kumars-frontdoor23.azurefd.net"
      custom_https_configuration = {
        certificate_source                         = "AzureKeyVault"
        azure_key_vault_certificate_vault_id       = ""       # valid keyvalut id
        azure_key_vault_certificate_secret_name    = ""       # valid certificate secret
        azure_key_vault_certificate_secret_version = "Latest" # optional, use "latest" if not defined
      }
    }
  ]

  # Azure Front Door Web Application Firewall Policy configuration

  web_application_firewall_policy = {
    name                              = "examplefdwafpolicy"
    mode                              = "Prevention"
    redirect_url                      = "https://www.contoso.com"
    custom_block_response_status_code = 403
    custom_block_response_body        = "PGh0bWw+CjxoZWFkZXI+PHRpdGxlPkhlbGxvPC90aXRsZT48L2hlYWRlcj4KPGJvZHk+CkhlbGxvIHdvcmxkCjwvYm9keT4KPC9odG1sPg=="

    custom_rule = {
      custom_rule1 = {
        name     = "Rule1"
        action   = "Block"
        enabled  = true
        priority = 1
        type     = "MatchRule"
        match_condition = {
          match_variable     = "RequestHeader"
          match_values       = ["windows"]
          operator           = "Contains"
          selector           = "UserAgent"
          negation_condition = false
          transforms         = ["Lowercase", "Trim"]
        }
        rate_limit_duration_in_minutes = 1
        rate_limit_threshold           = 10
      }
    }

    managed_rule = {
      managed_rule1 = {
        type    = "DefaultRuleSet"
        version = "1.0"
        exclusion = {
          exclusion1 = {
            match_variable = "QueryStringArgNames"
            operator       = "Equals"
            selector       = "not_suspicious"
          }
        }
        override = {
          override1 = {
            rule_group_name = "PHP"
            exclusion = {
              exclusion1 = {
                match_variable = "QueryStringArgNames"
                operator       = "Equals"
                selector       = "not_suspicious"
              }
            }
            rule = {
              rule1 = {
                rule_id = "933100"
                action  = "Block"
                enabled = false
                exclusion = {
                  exclusion1 = {
                    match_variable = "QueryStringArgNames"
                    operator       = "Equals"
                    selector       = "not_suspicious"
                  }
                }
              }
            }
          }
        }
      }
    }
  }

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

## Terraform Usage

To run this example you need to execute following Terraform commands

```hcl
terraform init
terraform plan
terraform apply
```

Run `terraform destroy` when you don't need these resources.
