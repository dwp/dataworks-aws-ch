resource "aws_s3_bucket_object" "cluster" {
  bucket = local.publish_bucket.id
  key    = "emr/ch/cluster.yaml"
  content = templatefile("cluster_config/cluster.yaml.tpl",
    {
      s3_log_bucket          = local.logstore_bucket
      s3_log_prefix          = local.s3_log_prefix
      ami_id                 = var.emr_ami_id
      service_role           = aws_iam_role.ch_emr_service.arn
      instance_profile       = aws_iam_instance_profile.ch.arn
      security_configuration = aws_emr_security_configuration.ebs_emrfs_em
      emr_release            = var.emr_release[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "instances" {
  bucket = local.publish_bucket.id
  key    = "emr/ch/instances.yaml"
  content = templatefile("cluster_config/instances.yaml.tpl",
    {
      keep_cluster_alive  = local.keep_cluster_alive[local.environment]
      add_master_sg       = aws_security_group.ch_common.id
      add_slave_sg        = aws_security_group.ch_common
      subnet_ids          = data.terraform_remote_state.internal_compute.outputs.ch_subnet.ids
      master_sg           = aws_security_group.ch_master.id
      slave_sg            = aws_security_group.ch_slave.id
      service_access_sg   = aws_security_group.ch_emr_service.id
      instance_type       = var.emr_instance_type[local.environment]
      core_instance_count = var.emr_core_instance_count[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "steps" {
  bucket = local.publish_bucket.id
  key    = "emr/ch/steps.yaml"
  content = templatefile("cluster_config/steps.yaml.tpl",
    {
      s3_config_bucket  = local.publish_bucket.id
      action_on_failure = local.step_fail_action[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "configurations" {
  bucket = local.publish_bucket.id
  key    = "emr/ch/configurations.yaml"
  content = templatefile("cluster_config/configurations.yaml.tpl",
    {
      environment                   = local.environment
      s3_log_bucket                 = local.logstore_bucket
      s3_log_prefix                 = local.s3_log_prefix
      s3_published_bucket           = local.publish_bucket
      proxy_no_proxy                = replace(replace(local.no_proxy, ",", "|"), ".s3", "*.s3")
      proxy_http_host               = local.proxy_host
      proxy_http_port               = local.proxy_port
      proxy_https_host              = local.proxy_host
      proxy_https_port              = local.proxy_port
      spark_executor_cores          = local.spark_executor_cores
      spark_executor_memory         = local.spark_executor_memory
      spark_executor_memoryOverhead = local.spark_executor_memoryOverhead
      spark_driver_memory           = local.spark_driver_memory
      spark_driver_cores            = local.spark_driver_cores
      spark_executor_instances      = local.spark_num_executors_per_instance
      spark_default_parallelism     = local.spark_default_parallelism
      spark_kyro_buffer             = local.spark_kyro_buffer
      hive_metsatore_username       = local.ch_writer.username
      hive_metastore_pwd            = local.ch_writer.secret_name
      hive_metastore_endpoint       = local.rds_cluster.endpoint
      hive_metastore_database_name  = local.rds_cluster.database_name
    }
  )
}
