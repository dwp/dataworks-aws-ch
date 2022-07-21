variable "root_certificate_authority_arn" {
  type = string
}
variable "ch_emr_launcher_lambda_role_arn" {}
variable "data_config_bucket" {}
variable "local_env_prefix" {}
variable "local_environment" {}
variable "local_dataworks_domain_name" {}
variable "local_ebs_emrfs_em" {}
variable "local_common_tags" {}
variable "ch_ebs_cmk_policy" {}
variable "ch_publish_for_trigger_policy" {}
variable "data_internal_compute_vpc_id" {}
variable "emr_launcher_zip" {
  type = map(string)
  default = {
    base_path = "../emr-launcher-release"
    version   = "1.0.36"
  }
}
