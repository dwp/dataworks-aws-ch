locals {
  emr_cluster_name       = "ch"
  master_instance_type   = "m5.2xlarge"
  master_instance_count  = 1
  core_instance_type     = "m5.2xlarge"
  core_instance_count    = 1
  task_instance_type     = "m5.2xlarge"
  task_instance_count    = 0
  dks_port               = 8443
  env_certificate_bucket = "dw-${local.environment}-public-certificates"
  dks_endpoint           = data.terraform_remote_state.crypto.outputs.dks_endpoint[local.environment]

  crypto_workspace = {
    management-dev = "management-dev"
    management     = "management"
  }

  management_workspace = {
    management-dev = "default"
    management     = "management"
  }

  management_account = {
    development = "management-dev"
    qa          = "management-dev"
    integration = "management-dev"
    preprod     = "management"
    production  = "management"
  }

  root_dns_name = {
    development = "dev.dataworks.dwp.gov.uk"
    qa          = "qa.dataworks.dwp.gov.uk"
    integration = "int.dataworks.dwp.gov.uk"
    preprod     = "pre.dataworks.dwp.gov.uk"
    production  = "dataworks.dwp.gov.uk"
  }

  ch_log_level = {
    development = "DEBUG"
    qa          = "DEBUG"
    integration = "DEBUG"
    preprod     = "INFO"
    production  = "INFO"
  }

  amazon_region_domain = "${data.aws_region.current.name}.amazonaws.com"
  endpoint_services    = ["dynamodb", "ec2", "ec2messages", "kms", "logs", "monitoring", ".s3", "s3", "secretsmanager", "ssm", "ssmmessages", "sts"]
  no_proxy             = "169.254.169.254,${join(",", formatlist("%s.%s", local.endpoint_services, local.amazon_region_domain))}"

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
          AwsKmsKey                 = module.ch_additional_services.ch_ebs_cmk.arn
        }
      }
    }
  }

  keep_cluster_alive = {
    development = true
    qa          = false
    integration = false
    preprod     = true
    production  = false
  }

  step_fail_action = {
    development = "CONTINUE"
    qa          = "CONTINUE"
    integration = "CONTINUE"
    preprod     = "CONTINUE"
    production  = "CONTINUE"
  }

  cw_agent_namespace        = "/app/ch"
  cw_agent_log_group_name   = "/app/ch"
  bootstrap_log_group_name  = "/app/ch/bootstrap_actions"
  steps_log_group_name      = "/app/ch/step_logs"
  yarn_spark_log_group_name = "/app/ch/yarn-spark_logs"
  e2e_log_group_name        = "/app/ch/e2e_logs"

  s3_log_prefix = "emr/ch"

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
  metrics_namespace = "app/ch/"
  ch_s3_prefix      = "component/ch"

  # See https://aws.amazon.com/blogs/big-data/best-practices-for-successfully-managing-memory-for-apache-spark-applications-on-amazon-emr/
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


}
