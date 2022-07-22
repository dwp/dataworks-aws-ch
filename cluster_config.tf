resource "aws_s3_bucket_object" "cluster" {
  bucket = var.data_config_bucket_id
  key    = "emr/ch/cluster.yaml"
  content = templatefile("cluster_config/cluster.yaml.tpl",
    {
      s3_log_bucket          = var.data_logstore_bucket_id
      s3_log_prefix          = var.local_s3_log_prefix
      ami_id                 = var.var_emr_ami_id
      service_role           = var.ch_emr_service.arn
      instance_profile       = var.ch_instance_profile
      security_configuration = var.emr_security_conf_id
      emr_release            = var.var_emr_release[var.local_environment]
    }
  )
}

resource "aws_s3_bucket_object" "instances" {
  bucket = var.data_config_bucket_id
  key    = "emr/ch/instances.yaml"
  content = templatefile("cluster_config/instances.yaml.tpl",
    {
      keep_cluster_alive  = var.local_keep_cluster_alive[var.local_environment]
      add_master_sg       = var.ch_sg_common
      add_slave_sg        = var.ch_sg_common
      subnet_ids          = join(",", var.data_subnet_ids)
      master_sg           = var.ch_sg_master
      slave_sg            = var.ch_sg_slave
      service_access_sg   = var.ch_sg_emr_service
      instance_type       = var.var_emr_instance_type[var.local_environment]
      core_instance_count = var.var_emr_core_instance_count[var.local_environment]
    }
  )
}

resource "aws_s3_bucket_object" "steps" {
  bucket = var.data_config_bucket_id
  key    = "emr/ch/steps.yaml"
  content = templatefile("cluster_config/steps.yaml.tpl",
    {
      s3_config_bucket  = var.data_config_bucket_id
      action_on_failure = var.local_step_fail_action[var.local_environment]
    }
  )
}


resource "aws_s3_bucket_object" "configurations" {
  bucket = var.data_config_bucket_id
  key    = "emr/ch/configurations.yaml"
  content = templatefile("cluster_config/configurations.yaml.tpl",
    {
      s3_log_bucket                 = var.data_logstore_bucket_id
      s3_log_prefix                 = var.local_s3_log_prefix
      s3_published_bucket           = var.data_published_bucket_id
      proxy_no_proxy                = replace(replace(var.local_no_proxy, ",", "|"), ".s3", "*.s3")
      proxy_http_host               = var.data_internet_proxy_host
      proxy_http_port               = var.data_internet_proxy_port
      proxy_https_host              = var.data_internet_proxy_host
      proxy_https_port              = var.data_internet_proxy_port
      spark_executor_cores          = var.local_spark_executor_cores
      spark_executor_memory         = var.local_spark_executor_memory
      spark_executor_memoryOverhead = var.local_spark_executor_memoryOverhead
      spark_driver_memory           = var.local_spark_driver_memory
      spark_driver_cores            = var.local_spark_driver_cores
      spark_executor_instances      = var.local_spark_num_executors_per_instance
      spark_default_parallelism     = var.local_spark_default_parallelism
      spark_kyro_buffer             = var.local_spark_kyro_buffer
      hive_metsatore_username       = var.data_ch_writer.username
      hive_metastore_pwd            = var.data_ch_writer.secret_name
      hive_metastore_endpoint       = var.data_rds_cluster.endpoint
      hive_metastore_database_name  = var.data_rds_cluster.database_name
      environment                   = var.local_environment
    }
  )
}
