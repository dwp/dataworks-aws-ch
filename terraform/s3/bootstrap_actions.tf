resource "aws_s3_bucket_object" "emr_setup_sh" {
  bucket = var.data_config_bucket_id
  key    = "component/ch/emr-setup.sh"
  content = templatefile("bootstrap_actions/emr-setup.sh",
    {
      VERSION                         = var.local_ch_version[var.local_environment]
      LOG_LEVEL                       = var.local_ch_log_level[var.local_environment]
      ENVIRONMENT_NAME                = var.local_environment
      S3_COMMON_LOGGING_SHELL         = format("s3://%s/%s", var.data_config_bucket_id, var.data_app_logging_common_file_s3_id)
      S3_LOGGING_SHELL                = format("s3://%s/%s", var.data_config_bucket_id, aws_s3_bucket_object.logging_script.key)
      aws_default_region              = var.var_region
      full_proxy                      = var.data_internet_proxy_url
      full_no_proxy                   = var.local_no_proxy
      acm_cert_arn                    = var.ch_acm_certificate_arn
      private_key_alias               = "private_key"
      truststore_aliases              = join(",", var.var_truststore_aliases)
      truststore_certs                = "s3://${var.local_env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${var.data_public_certificate_bucket_id}/ca_certificates/dataworks/dataworks_root_ca.pem"
      dks_endpoint                    = var.data_dks_endpoint[var.local_environment]
      cwa_metrics_collection_interval = 60
      cwa_namespace                   = var.local_cw_agent_namespace
      cwa_log_group_name              = var.cw_agent_log_group_name
      S3_CLOUDWATCH_SHELL             = format("s3://%s/%s", var.data_config_bucket_id, aws_s3_bucket_object.cloudwatch_sh.key)
      cwa_bootstrap_loggrp_name       = var.bootstrap_log_group_name
      cwa_steps_loggrp_name           = var.steps_log_group_name
      cwa_yarnspark_loggrp_name       = var.local_yarn_spark_log_group_name
      cwa_tests_loggrp_name           = var.e2e_log_group_name
      name                            = var.local_emr_cluster_name
      s3_bucket_id                    = var.data_config_bucket_id
      s3_bucket_prefix                = var.local_ch_s3_prefix
  })
}

resource "aws_s3_bucket_object" "ssm_script" {
  bucket  = var.data_config_bucket_id
  key     = "${var.local_ch_s3_prefix}/start_ssm.sh"
  content = file("bootstrap_actions/start_ssm.sh")
}

resource "aws_s3_bucket_object" "installer_sh" {
  bucket = var.data_config_bucket_id
  key    = "${var.local_ch_s3_prefix}/installer.sh"
  content = templatefile("bootstrap_actions/installer.sh",
    {
      full_proxy    = var.data_internet_proxy_url
      full_no_proxy = var.local_no_proxy
    }
  )
}

resource "aws_s3_bucket_object" "logging_script" {
  bucket  = var.data_config_bucket_id
  key     = "${var.local_ch_s3_prefix}/logging.sh"
  content = file("bootstrap_actions/logging.sh")
}

resource "aws_s3_bucket_object" "cloudwatch_sh" {
  bucket = var.data_config_bucket_id
  key    = "${var.local_ch_s3_prefix}/cloudwatch.sh"
  content = templatefile("bootstrap_actions/cloudwatch.sh",
    {
      emr_release = var.var_emr_release[var.local_environment]
    }
  )
}

resource "aws_s3_bucket_object" "download_steps_code" {
  bucket = var.data_config_bucket_id
  key    = "${var.local_ch_s3_prefix}/download_steps_code.sh"
  content = templatefile("bootstrap_actions/download_steps_code.sh",
    {
      s3_bucket_id     = var.data_config_bucket_id
      s3_bucket_prefix = var.local_ch_s3_prefix
    }
  )
}

resource "aws_s3_bucket_object" "metrics_pom" {
  bucket  = var.data_config_bucket_id
  key     = "${var.local_ch_s3_prefix}/metrics/pom.xml"
  content = file("bootstrap_actions/metrics_config/pom.xml")
}

resource "aws_s3_bucket_object" "prometheus_config" {
  bucket  = var.data_config_bucket_id
  key     = "${var.local_ch_s3_prefix}/metrics/prometheus_config.yml"
  content = file("bootstrap_actions/metrics_config/prometheus_config.yml")
}
