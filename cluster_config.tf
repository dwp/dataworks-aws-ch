resource "aws_s3_bucket_object" "cluster" {
  bucket = local.config_bucket.id
  key    = "emr/ch/cluster.yaml"
  content = templatefile("cluster_config/cluster.yaml.tpl",
    {
      s3_log_bucket          = local.logstore_bucket.id
      s3_log_prefix          = local.s3_log_prefix
      ami_id                 = var.emr_ami_id
      service_role           = aws_iam_role.ch_emr_service.arn
      instance_profile       = aws_iam_instance_profile.ch.arn
      security_configuration = aws_emr_security_configuration.ebs_emrfs_em.id
      emr_release            = var.emr_release[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "instances" {
  bucket = local.config_bucket.id
  key    = "emr/ch/instances.yaml"
  content = templatefile("cluster_config/instances.yaml.tpl",
    {
      keep_cluster_alive = local.keep_cluster_alive[local.environment]
      add_master_sg      = aws_security_group.ch_common.id
      add_slave_sg       = aws_security_group.ch_common.id
      subnet_ids = (
        local.use_capacity_reservation[local.environment] == true ?
        data.terraform_remote_state.internal_compute.outputs.ch_subnet.subnets[index(data.terraform_remote_state.internal_compute.outputs.ch_subnet.subnets.*.availability_zone, data.terraform_remote_state.common.outputs.ec2_capacity_reservations.emr_m5_16_x_large_2a.availability_zone)].id :
        data.terraform_remote_state.internal_compute.outputs.ch_subnet.subnets[index(data.terraform_remote_state.internal_compute.outputs.ch_subnet.subnets.*.availability_zone, data.terraform_remote_state.common.outputs.aws_ec2_non_capacity_reservation_region)].id
      )
      master_sg           = aws_security_group.ch_master.id
      slave_sg            = aws_security_group.ch_slave.id
      service_access_sg   = aws_security_group.ch_emr_service.id
      instance_type       = var.emr_instance_type[local.environment]
      core_instance_count = var.emr_core_instance_count[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "steps" {
  bucket = local.config_bucket.id
  key    = "emr/ch/steps.yaml"
  content = templatefile("cluster_config/steps.yaml.tpl",
    {
      s3_config_bucket  = local.config_bucket.id
      action_on_failure = local.step_fail_action[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "configurations" {
  bucket = local.config_bucket.id
  key    = "emr/ch/configurations.yaml"
  content = templatefile("cluster_config/configurations.yaml.tpl",
    {
      environment                   = local.environment
      s3_log_bucket                 = local.logstore_bucket.id
      s3_log_prefix                 = local.s3_log_prefix
      s3_published_bucket           = local.publish_bucket.id
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
      hive_metastore_username       = local.ch_writer.username
      hive_metastore_pwd            = local.ch_writer.secret_name
      hive_metastore_endpoint       = local.rds_cluster.endpoint
      hive_metastore_database_name  = local.rds_cluster.database_name
      hive_metastore_location       = "data/uc_ch"
      hive_compaction_threads       = local.hive_compaction_threads[local.environment]
      hive_tez_sessions_per_queue   = local.hive_tez_sessions_per_queue[local.environment]
      hive_max_reducers             = local.hive_max_reducers[local.environment]
      tez_am_resource_memory_mb     = local.tez_am_resource_memory_mb[local.environment]

    }
  )
}
