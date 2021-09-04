output "backend_pools" {
  description = "The ID of the Azure Front Door Backend Pool"
  value       = module.frontdoor.backend_pools
}

output "backend_pool_health_probes" {
  description = "The ID's of the Azure Front Door Backend Health Probe"
  value       = module.frontdoor.backend_pool_health_probes
}

output "backend_pool_load_balancing" {
  description = "The ID of the Azure Front Door Backend Load Balancer"
  value       = module.frontdoor.backend_pool_load_balancing
}

output "frontend_endpoint_id" {
  description = "The ID of the Azure Front Door Frontend Endpoint"
  value       = module.frontdoor.frontend_endpoint_id
}


output "frontdoor_id" {
  description = "The ID of the FrontDoor"
  value       = module.frontdoor.frontdoor_id
}

output "frontdoor_waf_policy_id" {
  description = "The ID of the FrontDoor Firewall Policy"
  value       = module.frontdoor.frontdoor_waf_policy_id
}

output "frontdoor_waf_policy_location" {
  description = "The Azure Region where this FrontDoor Firewall Policy exists"
  value       = module.frontdoor.frontdoor_waf_policy_location
}

output "frontdoor_waf_policy_frontend_endpoint_ids" {
  description = "The Frontend Endpoints associated with this Front Door Web Application Firewall policy"
  value       = module.frontdoor.frontdoor_waf_policy_frontend_endpoint_ids
}
