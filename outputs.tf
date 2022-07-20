output "kickstart_adg_common_sg" {
  value = {
    id = module.kickstart_security_groups.kickstart_adg_common_sg
  }
}

output "private_dns" {
  value = {
    kickstart_adg_service_discovery_dns = module.kickstart_additional_services.kickstart_adg_service_discovery_dns
    kickstart_adg_service_discovery     = module.kickstart_additional_services.kickstart_adg_service_discovery
  }
}
