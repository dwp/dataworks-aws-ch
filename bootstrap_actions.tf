resource "aws_s3_bucket_object" "emr_setup_sh" {
  bucket = local.config_bucket.id
  key    = "component/dataworks-aws-ch/emr-setup.sh"
  content = templatefile("bootstrap_actions/emr-setup.sh",
    {
      VERSION                         = local.ch_version[local.environment]
      LOG_LEVEL                       = local.ch_log_level[local.environment]
      ENVIRONMENT_NAME                = local.environment
      S3_COMMON_LOGGING_SHELL         = format("s3://%s/%s", local.config_bucket.id, data.terraform_remote_state.common.outputs.application_logging_common_file.s3_id)
      S3_LOGGING_SHELL                = format("s3://%s/%s", local.config_bucket.id, aws_s3_bucket_object.logging_script.key)
      aws_default_region              = var.region
      full_proxy                      = local.full_proxy
      full_no_proxy                   = local.no_proxy
      acm_cert_arn                    = aws_acm_certificate.ch.arn
      private_key_alias               = "private_key"
      truststore_aliases              = join(",", var.truststore_aliases)
      truststore_certs                = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem"
      dks_endpoint                    = data.terraform_remote_state.crypto.outputs.dks_endpoint[local.environment]
      cwa_metrics_collection_interval = 60
      cwa_namespace                   = local.cw_agent_namespace
      cwa_log_group_name              = local.cw_agent_log_group_name
      S3_CLOUDWATCH_SHELL             = format("s3://%s/%s", local.config_bucket.id, aws_s3_bucket_object.cloudwatch_sh.key)
      cwa_bootstrap_loggrp_name       = local.bootstrap_log_group_name
      cwa_steps_loggrp_name           = local.steps_log_group_name
      cwa_yarnspark_loggrp_name       = local.yarn_spark_log_group_name
      cwa_tests_loggrp_name           = local.e2e_log_group_name
      name                            = local.emr_cluster_name
  })
}

resource "aws_s3_bucket_object" "installer_sh" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/installer.sh"
  content = templatefile("bootstrap_actions/installer.sh",
    {
      full_proxy    = local.full_proxy
      full_no_proxy = local.no_proxy
    }
  )
}

resource "aws_s3_bucket_object" "logging_script" {
  bucket  = local.config_bucket.id
  key     = "${local.ch_s3_prefix}/logging.sh"
  content = file("bootstrap_actions/logging.sh")
}

resource "aws_s3_bucket_object" "cloudwatch_sh" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/cloudwatch.sh"
  content = templatefile("bootstrap_actions/cloudwatch.sh",
    {
      emr_release = var.emr_release[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "download_steps_code" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/download_steps_code.sh"
  content = templatefile("bootstrap_actions/download_steps_code.sh",
    {
      s3_bucket_id     = local.config_bucket.id
      s3_bucket_prefix = local.ch_s3_prefix
    }
  )
}
