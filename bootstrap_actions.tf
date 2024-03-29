resource "aws_s3_bucket_object" "metadata_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/dataworks-aws-ch/metadata.sh"
  content    = file("${path.module}/bootstrap_actions/metadata.sh")
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_object" "config_hcs_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/dataworks-aws-ch/config_hcs.sh"
  content    = file("${path.module}/bootstrap_actions/config_hcs.sh")
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "download_scripts_sh" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  key    = "component/dataworks-aws-ch/download-scripts.sh"
  content = templatefile("${path.module}/bootstrap_actions/download-scripts.sh",
    {
      VERSION                 = local.ch_version[local.environment]
      CH_LOG_LEVEL            = local.ch_log_level[local.environment]
      ENVIRONMENT_NAME        = local.environment
      S3_COMMON_LOGGING_SHELL = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, data.terraform_remote_state.common.outputs.application_logging_common_file.s3_id)
      S3_LOGGING_SHELL        = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.logging_script.key)
      scripts_location        = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, "component/dataworks-aws-ch")
  })
}

resource "aws_s3_bucket_object" "emr_setup_sh" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  key    = "component/dataworks-aws-ch/emr-setup.sh"
  content = templatefile("${path.module}/bootstrap_actions/emr-setup.sh",
    {
      CH_LOG_LEVEL                    = local.ch_log_level[local.environment]
      aws_default_region              = "eu-west-2"
      full_proxy                      = data.terraform_remote_state.internal_compute.outputs.internet_proxy.url
      full_no_proxy                   = local.no_proxy
      acm_cert_arn                    = aws_acm_certificate.ch_cert.arn
      private_key_alias               = "private_key"
      truststore_aliases              = join(",", var.truststore_aliases)
      truststore_certs                = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem"
      dks_endpoint                    = data.terraform_remote_state.crypto.outputs.dks_endpoint[local.environment]
      cwa_metrics_collection_interval = 60
      cwa_namespace                   = local.cw_agent_namespace
      cwa_log_group_name              = local.cw_agent_log_group_name
      S3_CLOUDWATCH_SHELL             = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.cloudwatch_sh.key)
      cwa_bootstrap_loggrp_name       = local.bootstrap_log_group_name
      cwa_steps_loggrp_name           = local.steps_log_group_name
      cwa_tests_loggrp_name           = local.e2e_log_group_name
      cwa_yarnspark_loggrp_name       = local.yarn_spark_log_group_name
      name                            = local.emr_cluster_name
      publish_bucket_id               = data.terraform_remote_state.common.outputs.published_bucket.id
  })
}

resource "aws_s3_bucket_object" "ssm_script" {
  bucket  = data.terraform_remote_state.common.outputs.config_bucket.id
  key     = "component/dataworks-aws-ch/start-ssm.sh"
  content = file("${path.module}/bootstrap_actions/start-ssm.sh")
}

resource "aws_s3_bucket_object" "installer_sh" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  key    = "component/dataworks-aws-ch/installer.sh"
  content = templatefile("${path.module}/bootstrap_actions/installer.sh",
    {
      full_proxy    = data.terraform_remote_state.internal_compute.outputs.internet_proxy.url
      full_no_proxy = local.no_proxy
    }
  )
}


resource "aws_s3_bucket_object" "logging_script" {
  bucket  = data.terraform_remote_state.common.outputs.config_bucket.id
  key     = "component/dataworks-aws-ch/logging.sh"
  content = file("${path.module}/bootstrap_actions/logging.sh")
}


resource "aws_s3_bucket_object" "cloudwatch_sh" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  key    = "component/dataworks-aws-ch/cloudwatch.sh"
  content = templatefile("${path.module}/bootstrap_actions/cloudwatch.sh",
    {
      emr_release = var.emr_release[local.environment]
    }
  )
}


resource "aws_s3_bucket_object" "hive_setup_sh" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  key    = "component/dataworks-aws-ch/steps-setup.sh"
  content = templatefile("${path.module}/bootstrap_actions/steps-setup.sh",
    {
      etl_script   = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.etl.key)
      etl_e2e      = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.e2e.key)
      etl_e2e_conf = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.e2e_conf.key)
      etl_conf     = format("s3://%s/%s", data.terraform_remote_state.common.outputs.config_bucket.id, aws_s3_bucket_object.steps_conf.key)
    }
  )
}
