output "front_door_backend" {
  description = "The ID of the Azure Front Door Backend Pool"
  value       = azurerm_frontdoor.main.*.backend_pool.0.id
}
