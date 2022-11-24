locals {
  emr_cluster_name        = "ch"
  dks_port                = 8443
  env_certificate_bucket  = "dw-${local.environment}-public-certificates"
  mgt_certificate_bucket  = "dw-${local.management_account[local.environment]}-public-certificates"
  dks_endpoint            = data.terraform_remote_state.crypto.outputs.dks_endpoint[local.environment]
  internal_compute_vpc_id = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.vpc.id
  monitoring_topic_arn    = data.terraform_remote_state.security-tools.outputs.sns_topic_london_monitoring.arn
  crypto_workspace = {
    management-dev = "management-dev"
    management     = "management"
  }
  audit_table = data.terraform_remote_state.internal_compute.outputs.data_pipeline_metadata_dynamo
  management_workspace = {
    management-dev = "default"
    management     = "management"
  }
  steps = ["etl"]
  management_account = {
    development = "management-dev"
    qa          = "management-dev"
    integration = "management-dev"
    preprod     = "management"
    production  = "management"
  }

  ch_log_level = {
    development = "DEBUG"
    qa          = "DEBUG"
    integration = "DEBUG"
    preprod     = "INFO"
    production  = "INFO"
  }

  amazon_region_domain = "${data.aws_region.current.name}.amazonaws.com"
  endpoint_services = [
    "dynamodb",
    "ec2",
    "ec2messages",
    "glue",
    "kms",
    "logs",
    "monitoring",
    ".s3",
    "s3",
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "sts"]
  no_proxy = "169.254.169.254,${join(",", formatlist("%s.%s", local.endpoint_services, local.amazon_region_domain))}"
  emr_subnet_non_capacity_reserved_environments = data.terraform_remote_state.common.outputs.aws_ec2_non_capacity_reservation_region

  emr_capacity_reservation_preference     = local.use_capacity_reservation[local.environment] == true ? "open" : "none"
  emr_capacity_reservation_usage_strategy = local.use_capacity_reservation[local.environment] == true ? "use-capacity-reservations-first" : ""
  hive_metastore_backend = {
    development = "aurora"
    qa          = "aurora"
    integration = "aurora"
    preprod     = "aurora"
    production  = "aurora"
  }

  ebs_emrfs_em = {
    EncryptionConfiguration = {
      EnableInTransitEncryption = false
      EnableAtRestEncryption    = true
      AtRestEncryptionConfiguration = {

        S3EncryptionConfiguration = {
          EncryptionMode             = "CSE-Custom"
          S3Object                   = "s3://${data.terraform_remote_state.management_artefact.outputs.artefact_bucket.id}/emr-encryption-materials-provider/encryption-materials-provider-all.jar"
          EncryptionKeyProviderClass = "uk.gov.dwp.dataworks.dks.encryptionmaterialsprovider.DKSEncryptionMaterialsProvider"
        }
        LocalDiskEncryptionConfiguration = {
          EnableEbsEncryption       = true
          EncryptionKeyProviderType = "AwsKms"
          AwsKmsKey                 = aws_kms_key.ch_ebs_cmk.arn
        }
      }
    }
  }

  keep_cluster_alive = {
    development = true
    qa          = true
    integration = false
    preprod     = true
    production  = false
  }

  use_capacity_reservation = {
    development = false
    qa          = false
    integration = false
    preprod     = false
    production  = true
  }

  step_fail_action = {
    development = "CONTINUE"
    qa          = "CONTINUE"
    integration = "TERMINATE_CLUSTER"
    preprod     = "CONTINUE"
    production  = "TERMINATE_CLUSTER"
  }

  hash_key                  = "Correlation_Id"
  range_key                 = "DataProduct"
  companies_s3_prefix       = "data/uc_ch/companies"
  rds_cluster               = data.terraform_remote_state.internal_compute.outputs.hive_metastore_v2.rds_cluster
  cw_agent_namespace        = "/app/dataworks-aws-ch"
  cw_agent_log_group_name   = "/app/dataworks-aws-ch"
  bootstrap_log_group_name  = "/app/dataworks-aws-ch/bootstrap_actions"
  steps_log_group_name      = "/app/dataworks-aws-ch/step_logs"
  yarn_spark_log_group_name = "/app/dataworks-aws-ch/yarn-spark_logs"
  e2e_log_group_name        = "/app/dataworks-aws-ch/e2e_logs"
  partitioning_column       = "date_sent"
  ch_writer                 = data.terraform_remote_state.internal_compute.outputs.metadata_store_users.ch_writer
  s3_log_prefix             = "emr/dataworks-aws-ch"
  stage_bucket              = data.terraform_remote_state.common.outputs.data_ingress_stage_bucket
  config_bucket             = data.terraform_remote_state.common.outputs.config_bucket
  full_proxy                = data.terraform_remote_state.internal_compute.outputs.internet_proxy.url
  proxy_host                = data.terraform_remote_state.internal_compute.outputs.internet_proxy.host
  proxy_port                = data.terraform_remote_state.internal_compute.outputs.internet_proxy.port
  proxy_sg                  = data.terraform_remote_state.internal_compute.outputs.internet_proxy.sg
  hive_metastore_location = "data/uc_ch"
  ch_version = {
    development = "0.0.1"
    qa          = "0.0.1"
    integration = "0.0.1"
    preprod     = "0.0.1"
    production  = "0.0.1"
  }
  metrics_namespace                = "app/dataworks-aws-ch/"
  ch_s3_prefix                     = "component/dataworks-aws-ch"
  publish_bucket                   = data.terraform_remote_state.common.outputs.published_bucket
  logstore_bucket                  = data.terraform_remote_state.security-tools.outputs.logstore_bucket

  emr_engine_version = {
    development = "5.7.mysql_aurora.2.10.2"
    qa          = "5.7.mysql_aurora.2.10.2"
    integration = "5.7.mysql_aurora.2.10.2"
    preprod     = "5.7.mysql_aurora.2.10.2"
    production  = "5.7.mysql_aurora.2.10.2"
  }

  hive_tez_container_size = {
    development = "2688"
    qa          = "2688"
    integration = "2688"
    preprod     = "2688"
    production  = "15360"
  }

  # 0.8 of hive_tez_container_size
  hive_tez_java_opts = {
    development = "-Xmx2150m"
    qa          = "-Xmx2150m"
    integration = "-Xmx2150m"
    preprod     = "-Xmx2150m"
    production  = "-Xmx12288m"
  }

  # 0.33 of hive_tez_container_size
  hive_auto_convert_join_noconditionaltask_size = {
    development = "896"
    qa          = "896"
    integration = "896"
    preprod     = "896"
    production  = "5068"
  }

  tez_runtime_unordered_output_buffer_size_mb = {
    development = "268"
    qa          = "268"
    integration = "268"
    preprod     = "268"
    production  = "2148"
  }

  # 0.4 of hive_tez_container_size
  tez_runtime_io_sort_mb = {
    development = "1075"
    qa          = "1075"
    integration = "1075"
    preprod     = "1075"
    production  = "6144"
  }

  tez_grouping_min_size = {
    development = "1342177"
    qa          = "1342177"
    integration = "1342177"
    preprod     = "1342177"
    production  = "52428800"
  }

  tez_grouping_max_size = {
    development = "268435456"
    qa          = "268435456"
    integration = "268435456"
    preprod     = "268435456"
    production  = "1073741824"
  }

  tez_am_resource_memory_mb = {
    development = "1024"
    qa          = "1024"
    integration = "1024"
    preprod     = "1024"
    production  = "12288"
  }

  # 0.8 of hive_tez_container_size
  tez_task_resource_memory_mb = {
    development = "1024"
    qa          = "1024"
    integration = "1024"
    preprod     = "1024"
    production  = "8196"
  }

  # 0.8 of tez_am_resource_memory_mb
  tez_am_launch_cmd_opts = {
    development = "-Xmx819m"
    qa          = "-Xmx819m"
    integration = "-Xmx819m"
    preprod     = "-Xmx819m"
    production  = "-Xmx6556m"
  }


  # See https://aws.amazon.com/blogs/big-data/best-practices-for-successfully-managing-memory-for-apache-spark-applications-on-amazon-emr/
  spark_executor_cores = {
    development = 1
    qa          = 1
    integration = 1
    preprod     = 5
    production  = 1
  }

  spark_executor_memory = {
    development = 10
    qa          = 10
    integration = 10
    preprod     = 37
    production  = 35 # At least 20 or more per executor core
  }

  spark_yarn_executor_memory_overhead = {
    development = 2
    qa          = 2
    integration = 2
    preprod     = 5
    production  = 7
  }

  spark_driver_memory = {
    development = 5
    qa          = 5
    integration = 5
    preprod     = 37
    production  = 10 # Doesn't need as much as executors
  }

  spark_driver_cores = {
    development = 1
    qa          = 1
    integration = 1
    preprod     = 5
    production  = 1
  }

  spark_executor_instances  = var.spark_executor_instances[local.environment]
  spark_default_parallelism = local.spark_executor_instances * local.spark_executor_cores[local.environment] * 2
  spark_kyro_buffer         = var.spark_kyro_buffer[local.environment]


  column_names                     = <<EOF
  {"CompanyName":"string","CompanyNumber":"int","RegAddress.CareOf":"string","RegAddress.POBox":"string","RegAddress.AddressLine1":"string", "RegAddress.AddressLine2":"string","RegAddress.PostTown":"string","RegAddress.County":"string","RegAddress.Country":"string","RegAddress.PostCode":"string","CompanyCategory":"string","CompanyStatus":"string","CountryOfOrigin":"string","DissolutionDate":"string","IncorporationDate":"string","Accounts.AccountRefDay":"string","Accounts.AccountRefMonth":"string","Accounts.NextDueDate":"string","Accounts.LastMadeUpDate":"string","Accounts.AccountCategory":"string","Returns.NextDueDate":"string","Returns.LastMadeUpDate":"string","Mortgages.NumMortCharges":"int","Mortgages.NumMortOutstanding":"int","Mortgages.NumMortPartSatisfied":"int","Mortgages.NumMortSatisfied":"int","SICCode.SicText_1":"string","SICCode.SicText_2":"string","SICCode.SicText_3":"string","SICCode.SicText_4":"string","LimitedPartnerships.NumGenPartners":"int","LimitedPartnerships.NumLimPartners":"int","URI":"string","PreviousName_1.CONDATE":"string", "PreviousName_1.CompanyName":"string", "PreviousName_2.CONDATE":"string", "PreviousName_2.CompanyName":"string","PreviousName_3.CONDATE":"string", "PreviousName_3.CompanyName":"string","PreviousName_4.CONDATE":"string", "PreviousName_4.CompanyName":"string","PreviousName_5.CONDATE":"string", "PreviousName_5.CompanyName":"string","PreviousName_6.CONDATE":"string", "PreviousName_6.CompanyName":"string","PreviousName_7.CONDATE":"string", "PreviousName_7.CompanyName":"string","PreviousName_8.CONDATE":"string", "PreviousName_8.CompanyName":"string","PreviousName_9.CONDATE":"string", "PreviousName_9.CompanyName":"string","PreviousName_10.CONDATE":"string", "PreviousName_10.CompanyName":"string","ConfStmtNextDueDate":"string", "ConfStmtLastMadeUpDate":"string"}
  EOF
}
