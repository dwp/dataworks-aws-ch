output "kickstart_adg_common_sg" {
  value = {
    id = module.kickstart_security_groups.kickstart_adg_common_sg
  }
}
