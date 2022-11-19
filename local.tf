locals {
  emr_cluster_name        = "ch"
  master_instance_type    = "m5.2xlarge"
  master_instance_count   = 1
  core_instance_type      = "m5.2xlarge"
  core_instance_count     = 1
  task_instance_type      = "m5.2xlarge"
  task_instance_count     = 0
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

  hive_tez_container_size = {
    development = "2688"
    qa          = "2688"
    integration = "2688"
    preprod     = "15360"
    production  = "15360"
  }

  # 0.8 of hive_tez_container_size
  hive_tez_java_opts = {
    development = "-Xmx2150m"
    qa          = "-Xmx2150m"
    integration = "-Xmx2150m"
    preprod     = "-Xmx12288m"
    production  = "-Xmx12288m"
  }

  # 0.33 of hive_tez_container_size
  hive_auto_convert_join_noconditionaltask_size = {
    development = "896"
    qa          = "896"
    integration = "896"
    preprod     = "5068"
    production  = "5068"
  }

  hive_bytes_per_reducer = {
    development = "13421728"
    qa          = "13421728"
    integration = "13421728"
    preprod     = "13421728"
    production  = "13421728"
  }

  tez_runtime_unordered_output_buffer_size_mb = {
    development = "268"
    qa          = "268"
    integration = "268"
    preprod     = "2148"
    production  = "2148"
  }

  # 0.4 of hive_tez_container_size
  tez_runtime_io_sort_mb = {
    development = "1075"
    qa          = "1075"
    integration = "1075"
    preprod     = "6144"
    production  = "6144"
  }

  tez_grouping_min_size = {
    development = "1342177"
    qa          = "1342177"
    integration = "1342177"
    preprod     = "52428800"
    production  = "52428800"
  }

  tez_grouping_max_size = {
    development = "268435456"
    qa          = "268435456"
    integration = "268435456"
    preprod     = "1073741824"
    production  = "1073741824"
  }

  tez_am_resource_memory_mb = {
    development = "1024"
    qa          = "1024"
    integration = "1024"
    preprod     = "12288"
    production  = "12288"
  }

  # 0.8 of hive_tez_container_size
  tez_task_resource_memory_mb = {
    development = "1024"
    qa          = "1024"
    integration = "1024"
    preprod     = "8196"
    production  = "8196"
  }

  # 0.8 of tez_am_resource_memory_mb
  tez_am_launch_cmd_opts = {
    development = "-Xmx819m"
    qa          = "-Xmx819m"
    integration = "-Xmx819m"
    preprod     = "-Xmx6556m"
    production  = "-Xmx6556m"
  }

  // This value should be the same as yarn.scheduler.maximum-allocation-mb
  llap_daemon_yarn_container_mb = {
    development = "57344"
    qa          = "57344"
    integration = "57344"
    preprod     = "385024"
    production  = "385024"
  }

  llap_number_of_instances = {
    development = "5"
    qa          = "5"
    integration = "5"
    preprod     = "20"
    production  = "29"
  }

  map_reduce_vcores_per_node = {
    development = "5"
    qa          = "5"
    integration = "5"
    preprod     = "15"
    production  = "15"
  }

  map_reduce_vcores_per_task = {
    development = "1"
    qa          = "1"
    integration = "1"
    preprod     = "5"
    production  = "5"
  }

  hive_max_reducers = {
    development = "1099"
    qa          = "1099"
    integration = "1099"
    preprod     = "3000"
    production  = "3000"
  }


  retry_max_attempts = {
    development = "10"
    qa          = "10"
    integration = "10"
    preprod     = "12"
    production  = "12"
  }

  retry_attempt_delay_seconds = {
    development = "5"
    qa          = "5"
    integration = "5"
    preprod     = "5"
    production  = "5"
  }

  retry_enabled = {
    development = "true"
    qa          = "true"
    integration = "true"
    preprod     = "true"
    production  = "true"
  }

  ch_processes = {
    development = "10"
    qa          = "10"
    integration = "10"
    preprod     = "20"
    production  = "20"
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
    integration = "CONTINUE"
    preprod     = "CONTINUE"
    production  = "CONTINUE"
  }
  hive_compaction_threads = {
    development = "1"
    qa          = "1"
    integration = "1"
    preprod     = "12"
    production  = "12"
    # vCPU in the instance / 8
  }

  hive_tez_sessions_per_queue = {
    development = "10"
    qa          = "10"
    integration = "10"
    preprod     = "35"
    production  = "35"
  }


  hash_key                  = "Correlation_Id"
  range_key                 = "DataProduct"
  hash_id                   = ""
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
  spark_num_cores_per_node         = var.emr_num_cores_per_core_instance[local.environment] - 1
  spark_num_nodes                  = local.core_instance_count + local.task_instance_count + local.master_instance_count
  spark_executor_cores             = var.num_cores_per_executor[local.environment]
  spark_total_avaliable_cores      = local.spark_num_cores_per_node * local.spark_num_nodes
  spark_total_avaliable_executors  = ceil(local.spark_total_avaliable_cores / local.spark_executor_cores) - 1
  spark_num_executors_per_instance = ceil(local.spark_total_avaliable_executors / local.spark_num_nodes)
  spark_executor_total_memory      = floor(var.ram_memory_per_node[local.environment] / local.spark_num_executors_per_instance) - 10
  spark_executor_memoryOverhead    = ceil(local.spark_executor_total_memory * 0.10)
  spark_executor_memory            = floor(local.spark_executor_total_memory - local.spark_executor_memoryOverhead)
  spark_driver_memory              = 1
  spark_driver_cores               = 1
  spark_default_parallelism        = local.spark_num_executors_per_instance * local.spark_executor_cores * 2
  spark_kyro_buffer                = var.spark_kyro_buffer[local.environment]
  column_names                     = <<EOF
  {"CompanyName":"string","CompanyNumber":"int","RegAddress.CareOf":"string","RegAddress.POBox":"string","RegAddress.AddressLine1":"string", "RegAddress.AddressLine2":"string","RegAddress.PostTown":"string","RegAddress.County":"string","RegAddress.Country":"string","RegAddress.PostCode":"string","CompanyCategory":"string","CompanyStatus":"string","CountryOfOrigin":"string","DissolutionDate":"string","IncorporationDate":"string","Accounts.AccountRefDay":"string","Accounts.AccountRefMonth":"string","Accounts.NextDueDate":"string","Accounts.LastMadeUpDate":"string","Accounts.AccountCategory":"string","Returns.NextDueDate":"string","Returns.LastMadeUpDate":"string","Mortgages.NumMortCharges":"int","Mortgages.NumMortOutstanding":"int","Mortgages.NumMortPartSatisfied":"int","Mortgages.NumMortSatisfied":"int","SICCode.SicText_1":"string","SICCode.SicText_2":"string","SICCode.SicText_3":"string","SICCode.SicText_4":"string","LimitedPartnerships.NumGenPartners":"int","LimitedPartnerships.NumLimPartners":"int","URI":"string","PreviousName_1.CONDATE":"string", "PreviousName_1.CompanyName":"string", "PreviousName_2.CONDATE":"string", "PreviousName_2.CompanyName":"string","PreviousName_3.CONDATE":"string", "PreviousName_3.CompanyName":"string","PreviousName_4.CONDATE":"string", "PreviousName_4.CompanyName":"string","PreviousName_5.CONDATE":"string", "PreviousName_5.CompanyName":"string","PreviousName_6.CONDATE":"string", "PreviousName_6.CompanyName":"string","PreviousName_7.CONDATE":"string", "PreviousName_7.CompanyName":"string","PreviousName_8.CONDATE":"string", "PreviousName_8.CompanyName":"string","PreviousName_9.CONDATE":"string", "PreviousName_9.CompanyName":"string","PreviousName_10.CONDATE":"string", "PreviousName_10.CompanyName":"string","ConfStmtNextDueDate":"string", "ConfStmtLastMadeUpDate":"string"}
  EOF
}
