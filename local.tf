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
  hive_max_reducers = {
    development = "1099"
    qa          = "1099"
    integration = "1099"
    preprod     = "2000"
    production  = "2000"
  }

  tez_am_resource_memory_mb = {
    development = "1024"
    qa          = "1024"
    integration = "1024"
    preprod     = "1024"
    production  = "1024"
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
  env_prefix = {
    development = "dev."
    qa          = "qa."
    stage       = "stg."
    integration = "int."
    preprod     = "pre."
    production  = ""
  }
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
