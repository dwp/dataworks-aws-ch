variable "local_common_tags" {
  description = "repository tags"
}

variable "local_environment" {
}

variable "data_config_bucket_arn" {
}
variable "data_config_bucket_id" {}

variable "data_config_bucket_cmk_arn" {
}

variable "local_ch_version" {
}

variable "data_app_logging_common_file_s3_id" {
}

variable "var_region" {
}

variable "local_no_proxy" {
}

variable "local_ch_log_level" {
}

variable "data_internet_proxy_url" {
}

variable "data_internet_proxy_port" {
}

variable "data_internet_proxy_host" {
}

variable "ch_acm_certificate_arn" {
}

variable "var_truststore_aliases" {
}

variable "local_env_certificate_bucket" {
}

variable "data_public_certificate_bucket_id" {
}

variable "data_dks_endpoint" {
}

variable "local_cw_agent_namespace" {
}

variable "cw_agent_log_group_name" {
}

variable "steps_log_group_name" {
}

variable "bootstrap_log_group_name" {
}

variable "e2e_log_group_name" {
  type = string
}

variable "local_yarn_spark_log_group_name" {
  type = string
}

variable "local_emr_cluster_name" {
  type = string
}

variable "local_ch_s3_prefix" {
  type = string
}
variable "var_emr_release" {
}

variable "ksr_s3_readonly_role_arn" {
  type = string
}
variable "data_published_bucket_id" {
}

variable "data_logstore_bucket_id" {}
variable "local_s3_log_prefix" {}
variable "var_emr_ami_id" {}
variable "ch_emr_service" {}
variable "ch_instance_profile" {}
variable "local_keep_cluster_alive" {}
variable "ch_sg_common" {}
variable "ch_sg_slave" {}
variable "ch_sg_master" {}
variable "ch_sg_emr_service" {}
variable "data_subnet_ids" {}
variable "var_emr_instance_type" {}
variable "var_emr_core_instance_count" {}
variable "local_step_fail_action" {}
variable "local_spark_num_cores_per_node" {}
variable "local_spark_num_nodes" {}
variable "local_spark_executor_cores" {}
variable "local_spark_total_avaliable_cores" {}
variable "local_spark_total_avaliable_executors" {}
variable "local_spark_num_executors_per_instance" {}
variable "local_spark_executor_total_memory" {}
variable "local_spark_executor_memoryOverhead" {}
variable "local_spark_executor_memory" {}
variable "local_spark_driver_memory" {}
variable "local_spark_driver_cores" {}
variable "local_spark_default_parallelism" {}
variable "local_spark_kyro_buffer" {}
variable "data_ch_writer" {}
variable "data_rds_cluster" {}
variable "emr_security_conf_id" {}
variable "data_stage_bucket" {}







