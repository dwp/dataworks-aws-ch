variable "local_environment" {
}

variable "local_common_tags" {
}

variable "data_kickstart_writer_secret_arn" {
}

variable "data_config_bucket_id" {
}
variable "data_config_bucket_arn" {
}

variable "data_config_bucket_cmk_arn" {
}

variable "data_ci_role_arn" {
}

variable "data_administrator_role_arn" {
}

variable "data_aws_config_role_arn" {
}

variable "ch_ebs_kms_key_arn" {
}

variable "local_applications_source_acc_nos" {
}

variable "local_applications_environment_mapping" {
}

variable "local_application_assume_iam_role" {
}

variable "local_source_acc_nos" {
}

variable "ch_acm_certificate_arn" {
}

variable "data_published_bucket_arn" {
}

variable "data_published_bucket_cmk" {
}

variable "ch_secret" {
}

variable "data_logstore_bucket_arn" {}
variable "local_s3_log_prefix" {}
variable "data_artefact_bucket" {}

variable "data_audit_table_name" {}

variable "var_region" {}
variable "local_account" {}
variable "data_sns_monitoring_topic_arn" {}
variable "ch_trigger_topic_arn" {}
