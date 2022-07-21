module "ch_cloud_watch" {
  source                           = "./terraform/cloud_watch"
  local_common_tags                = local.common_repo_tags
  data_sns_monitoring_topic_arn    = data.terraform_remote_state.security-tools.outputs.sns_topic_london_monitoring.arn
  local_bootstrap_log_group_name   = local.bootstrap_log_group_name
  local_steps_log_group_name       = local.steps_log_group_name
  local_yarn_spark_log_group_name  = local.yarn_spark_log_group_name
  local_e2e_log_group_name         = local.e2e_log_group_name
  local_cw_agent_log_group_name    = local.cw_agent_log_group_name
  local_metrics_namespace          = local.metrics_namespace
  var_steps_args                   = var.steps_args
  local_environment                = local.environment
  local_ch_adg_emr_lambda_schedule = local.ch_adg_emr_lambda_schedule
  ch_trigger_topic_arn             = module.ch_additional_services.ch_trigger_topic_arn

}

module "ch_iam" {
  source                                 = "./terraform/iam"
  local_common_tags                      = local.common_repo_tags
  local_environment                      = local.environment
  data_ch_writer_secret_arn              = data.terraform_remote_state.internal_compute.outputs.metadata_store_users.ch_adg_writer.secret_arn
  data_config_bucket_id                  = data.terraform_remote_state.common.outputs.config_bucket.id
  data_config_bucket_arn                 = data.terraform_remote_state.common.outputs.config_bucket.arn
  data_config_bucket_cmk_arn             = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  data_ci_role_arn                       = data.aws_iam_role.ci.arn
  data_administrator_role_arn            = data.aws_iam_role.administrator.arn
  data_aws_config_role_arn               = data.aws_iam_role.aws_config.arn
  ch_ebs_kms_key_arn                     = module.ch_additional_services.ch_ebs_kms_key_arn
  local_applications_source_acc_nos      = local.applications_source_acc_nos
  local_applications_environment_mapping = local.applications_environment_mapping
  local_application_assume_iam_role      = local.application_assume_iam_role
  local_source_acc_nos                   = local.source_acc_nos
  local_vacancies_environment_mapping    = local.vacancies_environment_mapping
  local_vacancies_assume_iam_role        = local.vacancies_assume_iam_role
  ch_acm_certificate_arn                 = module.ch_additional_services.ch_acm_certificate_arn
  data_published_bucket_arn              = data.terraform_remote_state.common.outputs.published_bucket.arn
  data_published_bucket_cmk              = data.terraform_remote_state.common.outputs.published_bucket_cmk.arn
  ch_secret                              = module.ch_additional_services.ch_secret
  data_logstore_bucket_arn               = data.terraform_remote_state.security-tools.outputs.logstore_bucket.arn
  local_s3_log_prefix                    = local.s3_log_prefix
  data_artefact_bucket                   = data.terraform_remote_state.management_artefact.outputs.artefact_bucket
  var_region                             = var.region
  local_account                          = local.account
  data_audit_table_name                  = data.terraform_remote_state.internal_compute.outputs.data_pipeline_metadata_dynamo.name
  data_sns_monitoring_topic_arn          = data.terraform_remote_state.security-tools.outputs.sns_topic_london_monitoring.arn
  ch_trigger_topic_arn                   = module.ch_additional_services.ch_trigger_topic_arn

}


module "ch_additional_services" {
  source = "./terraform/additional_services"
  providers = {
    aws                = aws
    aws.management_dns = aws.management_dns
  }
  root_certificate_authority_arn  = data.terraform_remote_state.aws_certificate_authority.outputs.root_ca.arn
  data_config_bucket              = data.terraform_remote_state.common.outputs.config_bucket
  ch_emr_launcher_lambda_role_arn = module.ch_iam.ch_emr_launcher_lambda_role_arn
  local_env_prefix                = local.env_prefix
  local_environment               = local.environment
  local_dataworks_domain_name     = local.dataworks_domain_name
  local_ebs_emrfs_em              = local.ebs_emrfs_em
  local_common_tags               = local.common_repo_tags
  ch_ebs_cmk_policy               = module.ch_iam.ch_ebs_cmk_policy
  ch_publish_for_trigger_policy   = module.ch_iam.ch_publish_for_trigger_policy
  data_internal_compute_vpc_id    = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.vpc.id
  emr_launcher_zip                = var.emr_launcher_zip
}

module "ch_s3" {
  source                          = "./terraform/s3"
  local_common_tags               = local.common_repo_tags
  local_yarn_spark_log_group_name = local.yarn_spark_log_group_name
  data_config_bucket_id           = data.terraform_remote_state.common.outputs.config_bucket.id
  data_config_bucket_arn          = data.terraform_remote_state.common.outputs.config_bucket.arn

  data_config_bucket_cmk_arn             = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  local_ch_adg_version                   = local.ch_adg_version
  local_environment                      = local.environment
  data_app_logging_common_file_s3_id     = data.terraform_remote_state.common.outputs.application_logging_common_file.s3_id
  var_region                             = var.region
  local_no_proxy                         = local.no_proxy
  local_ch_adg_log_level                 = local.ch_adg_log_level
  data_internet_proxy_port               = data.terraform_remote_state.internal_compute.outputs.internet_proxy.port
  data_internet_proxy_host               = data.terraform_remote_state.internal_compute.outputs.internet_proxy.host
  data_internet_proxy_url                = data.terraform_remote_state.internal_compute.outputs.internet_proxy.url
  ch_acm_certificate_arn                 = module.ch_additional_services.ch_acm_certificate_arn
  var_truststore_aliases                 = var.truststore_aliases
  local_env_certificate_bucket           = local.env_certificate_bucket
  data_public_certificate_bucket_id      = data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id
  data_dks_endpoint                      = data.terraform_remote_state.crypto.outputs.dks_endpoint
  local_cw_agent_namespace               = local.cw_agent_namespace
  cw_agent_log_group_name                = module.ch_cloud_watch.cw_agent_log_group_name
  steps_log_group_name                   = module.ch_cloud_watch.steps_log_group_name
  bootstrap_log_group_name               = module.ch_cloud_watch.bootstrap_log_group_name
  e2e_log_group_name                     = module.ch_cloud_watch.e2e_log_group_name
  local_emr_cluster_name                 = local.emr_cluster_name
  local_ch_s3_prefix                     = local.ch_s3_prefix
  var_emr_release                        = var.emr_release
  local_ch_adg_pushgateway_hostname      = module.ch_additional_services.ch_adg_pushgateway_hostname
  ksr_s3_readonly_role_arn               = module.ch_iam.dw_ksr_s3_readonly_arn
  data_published_bucket_id               = data.terraform_remote_state.common.outputs.published_bucket.id
  local_applications_source_acc_nos      = local.applications_source_acc_nos
  local_applications_environment_mapping = local.applications_environment_mapping
  local_application_assume_iam_role      = local.application_assume_iam_role
  local_source_acc_nos                   = local.source_acc_nos
  local_vacancies_environment_mapping    = local.vacancies_environment_mapping
  local_vacancies_assume_iam_role        = local.vacancies_assume_iam_role
  data_logstore_bucket_id                = data.terraform_remote_state.security-tools.outputs.logstore_bucket.id
  local_s3_log_prefix                    = local.s3_log_prefix
  var_emr_ami_id                         = var.emr_ami_id
  ch_emr_service                         = module.ch_iam.ch_emr_service
  ch_instance_profile                    = module.ch_iam.ch_instance_profile
  local_keep_cluster_alive               = local.keep_cluster_alive
  ch_sg_common                           = module.ch_security_groups.ch_sg_common
  ch_sg_master                           = module.ch_security_groups.ch_sg_master
  ch_sg_slave                            = module.ch_security_groups.ch_sg_slave
  ch_sg_emr_service                      = module.ch_security_groups.ch_sg_emr_service
  data_subnet_ids                        = data.terraform_remote_state.internal_compute.outputs.ch_adg_subnet.ids
  var_emr_instance_type                  = var.emr_instance_type
  var_emr_core_instance_count            = var.emr_core_instance_count
  local_step_fail_action                 = local.step_fail_action
  local_spark_num_cores_per_node         = local.spark_num_cores_per_node
  local_spark_num_nodes                  = local.spark_num_nodes
  local_spark_executor_cores             = local.spark_executor_cores
  local_spark_total_avaliable_cores      = local.spark_total_avaliable_cores
  local_spark_total_avaliable_executors  = local.spark_total_avaliable_executors
  local_spark_num_executors_per_instance = local.spark_num_executors_per_instance
  local_spark_executor_total_memory      = local.spark_executor_total_memory
  local_spark_executor_memoryOverhead    = local.spark_executor_memoryOverhead
  local_spark_executor_memory            = local.spark_executor_memory
  local_spark_driver_memory              = local.spark_driver_memory
  local_spark_driver_cores               = local.spark_driver_cores
  local_spark_default_parallelism        = local.spark_default_parallelism
  local_spark_kyro_buffer                = local.spark_kyro_buffer
  data_ch_writer                         = data.terraform_remote_state.internal_compute.outputs.metadata_store_users.ch_adg_writer
  data_rds_cluster                       = data.terraform_remote_state.internal_compute.outputs.hive_metastore_v2.rds_cluster
  emr_security_conf_id                   = module.ch_additional_services.emr_security_conf_id
}

module "ch_security_groups" {
  source = "./terraform/security_groups"
  providers = {
    aws = aws
  aws.crypto = aws.crypto }
  data_internal_compute_vpc_id = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.vpc.id
  data_metastore_v2_sg_id      = data.terraform_remote_state.internal_compute.outputs.hive_metastore_v2.security_group.id
  local_environment            = local.environment
  data_vpc_interface_sg_id     = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.interface_vpce_sg_id
  data_vpc_prefix_list_ids     = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.prefix_list_ids
  data_internet_proxy_sg       = data.terraform_remote_state.internal_compute.outputs.internet_proxy.sg
  data_cidr_blocks             = data.terraform_remote_state.crypto.outputs.dks_subnet.cidr_blocks
  data_ch_cidr_blocks          = data.terraform_remote_state.internal_compute.outputs.ch_adg_subnet.cidr_blocks
  data_dks_sg_id               = data.terraform_remote_state.crypto.outputs.dks_sg_id
}
