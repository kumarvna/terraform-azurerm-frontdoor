# Azure Front Door Terraform Module

Azure Front Door is a fast, reliable, and secure modern cloud CDN that uses the Microsoft global edge network and integrates with intelligent threat protection. It combines the capabilities of Azure Front Door, Azure Content Delivery Network (CDN) standard, and Azure Web Application Firewall (WAF) into a single secure cloud CDN platform.

This Terraform module helps create Microsoft's highly available and scalable web application acceleration platform and global HTTP(s) load balancer Azure Front Door Service with Web Application Firewall policies and SSL offloading.

## Module Usage for

* [Frontdoor with SSL Offloading](frontdoor_with_custom_https_configuration/)
* [Frontdoor with WAF Policies](frontdoor_with_waf_policies/)

## Terraform Usage

To run this example you need to execute following Terraform commands

```hcl
terraform init
terraform plan
terraform apply
```

Run `terraform destroy` when you don't need these resources.
