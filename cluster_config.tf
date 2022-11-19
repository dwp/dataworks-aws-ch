resource "aws_s3_bucket_object" "cluster" {
  bucket = local.config_bucket.id
  key    = "emr/dataworks-aws-ch-test/cluster.yaml"
  content = templatefile("cluster_config/cluster.yaml.tpl",
    {
      s3_log_bucket          = local.logstore_bucket.id
      s3_log_prefix          = local.s3_log_prefix
      ami_id                 = var.emr_ami_id
      service_role           = aws_iam_role.aws_ch_emr_service.arn
      instance_profile       = aws_iam_instance_profile.ch.arn
      security_configuration = aws_emr_security_configuration.ebs_emrfs_em.id
      emr_release            = var.emr_release[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "instances" {
  bucket = local.config_bucket.id
  key    = "emr/dataworks-aws-ch-test/instances.yaml"
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
      service_access_sg   = aws_security_group.service_sg_ch.id
      instance_type       = var.emr_instance_type[local.environment]
      core_instance_count = var.emr_core_instance_count[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "steps" {
  bucket = local.config_bucket.id
  key    = "emr/dataworks-aws-ch-test/steps.yaml"
  content = templatefile("cluster_config/steps.yaml.tpl",
    {
      s3_config_bucket  = local.config_bucket.id
      action_on_failure = local.step_fail_action[local.environment]
    }
  )
}

resource "aws_s3_bucket_object" "configurations" {
  bucket = local.config_bucket.id
  key    = "emr/dataworks-aws-ch-test/configurations.yaml"
  content = templatefile("cluster_config/configurations.yaml.tpl",
    {
      s3_log_bucket                                 = data.terraform_remote_state.security-tools.outputs.logstore_bucket.id
      s3_log_prefix                                 = local.s3_log_prefix
      proxy_no_proxy                                = replace(replace(local.no_proxy, ",", "|"), ".s3", "*.s3")
      proxy_http_host                               = data.terraform_remote_state.internal_compute.outputs.internet_proxy.host
      proxy_http_port                               = data.terraform_remote_state.internal_compute.outputs.internet_proxy.port
      proxy_https_host                              = data.terraform_remote_state.internal_compute.outputs.internet_proxy.host
      proxy_https_port                              = data.terraform_remote_state.internal_compute.outputs.internet_proxy.port
      environment                                   = local.environment
      hive_tez_container_size                       = local.hive_tez_container_size[local.environment]
      hive_tez_java_opts                            = local.hive_tez_java_opts[local.environment]
      hive_auto_convert_join_noconditionaltask_size = local.hive_auto_convert_join_noconditionaltask_size[local.environment]
      tez_grouping_min_size                         = local.tez_grouping_min_size[local.environment]
      tez_grouping_max_size                         = local.tez_grouping_max_size[local.environment]
      tez_am_resource_memory_mb                     = local.tez_am_resource_memory_mb[local.environment]
      tez_am_launch_cmd_opts                        = local.tez_am_launch_cmd_opts[local.environment]
      tez_runtime_io_sort_mb                        = local.tez_runtime_io_sort_mb[local.environment]
      tez_runtime_unordered_output_buffer_size_mb   = local.tez_runtime_unordered_output_buffer_size_mb[local.environment]
      hive_metsatore_username                       = data.terraform_remote_state.internal_compute.outputs.metadata_store_users.clive_writer.username
      hive_metastore_pwd                            = data.terraform_remote_state.internal_compute.outputs.metadata_store_users.clive_writer.secret_name
      hive_metastore_endpoint                       = data.terraform_remote_state.internal_compute.outputs.hive_metastore_v2.endpoint
      hive_metastore_database_name                  = data.terraform_remote_state.internal_compute.outputs.hive_metastore_v2.database_name
      hive_metastore_location                       = local.hive_metastore_location
      s3_published_bucket                           = data.terraform_remote_state.common.outputs.published_bucket.id
      s3_processed_bucket                           = data.terraform_remote_state.common.outputs.processed_bucket.id
      hive_bytes_per_reducer                        = local.hive_bytes_per_reducer[local.environment]
      hive_tez_sessions_per_queue                   = local.hive_tez_sessions_per_queue[local.environment]
      llap_number_of_instances                      = local.llap_number_of_instances[local.environment]
      llap_daemon_yarn_container_mb                 = local.llap_daemon_yarn_container_mb[local.environment]
      hive_auto_convert_join_noconditionaltask_size = local.hive_auto_convert_join_noconditionaltask_size[local.environment]
      hive_max_reducers                             = local.hive_max_reducers[local.environment]
      map_reduce_vcores_per_task                    = local.map_reduce_vcores_per_task[local.environment]
      map_reduce_vcores_per_node                    = local.map_reduce_vcores_per_node[local.environment]
      spark_executor_cores                          = 1
      spark_executor_cores                          = local.spark_executor_cores[local.environment]
      spark_executor_memory                         = local.spark_executor_memory
      spark_yarn_executor_memory_overhead           = 2
      spark_driver_memory                           = local.spark_driver_memory
      spark_driver_cores                            = local.spark_driver_cores
      spark_executor_instances                      = 50
      spark_default_parallelism                     = local.spark_default_parallelism
    }
  )
}
