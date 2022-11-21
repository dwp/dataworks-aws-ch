variable "truststore_aliases" {
  description = "comma seperated truststore aliases"
  type        = list(string)
  default     = ["dataworks_root_ca", "dataworks_mgt_root_ca"]
}

variable "emr_release" {
  default = {
    development = "6.2.0"
    qa          = "6.2.0"
    integration = "6.2.0"
    preprod     = "6.2.0"
    production  = "6.2.0"
  }
}

variable "emr_instance_type_master" {
  default = {
    development = "m5.4xlarge"
    qa          = "m5.4xlarge"
    integration = "m5.4xlarge"
    preprod     = "m5.4xlarge"
    production  = "m5.4xlarge"
  }
}

variable "emr_instance_type_core" {
  default = {
    development = "m5.4xlarge"
    qa          = "m5.4xlarge"
    integration = "m5.4xlarge"
    preprod     = "r5.4xlarge"
    production  = "r5.4xlarge"
  }
}

# Count of instances
variable "emr_core_instance_count" {
  default = {
    development = "10"
    qa          = "10"
    integration = "10"
    preprod     = "39"
    production  = "39"
  }
}

variable "emr_instance_type_master_one_incremental" {
  default = {
    development = "r5.2xlarge"
    qa          = "r5.2xlarge"
    integration = "r5.2xlarge"
    preprod     = "r5.8xlarge"
    production  = "r5.8xlarge"
  }
}

variable "emr_instance_type_master_two_incremental" {
  default = {
    development = "m5.4xlarge"
    qa          = "m5.4xlarge"
    integration = "m5.4xlarge"
    preprod     = "m5.16xlarge"
    production  = "m5.16xlarge"
  }
}

variable "emr_instance_type_core_one_incremental" {
  default = {
    development = "r5.2xlarge"
    qa          = "r5.2xlarge"
    integration = "r5.2xlarge"
    preprod     = "r5.8xlarge"
    production  = "r5.8xlarge"
  }
}

variable "emr_instance_type_core_two_incremental" {
  default = {
    development = "r4.2xlarge"
    qa          = "r4.2xlarge"
    integration = "r4.2xlarge"
    preprod     = "r4.8xlarge"
    production  = "r4.8xlarge"
  }
}

variable "emr_instance_type_core_three_incremental" {
  default = {
    development = "m5.4xlarge"
    qa          = "m5.4xlarge"
    integration = "m5.4xlarge"
    preprod     = "m5.16xlarge"
    production  = "m5.16xlarge"
  }
}

# Count of instances
variable "emr_core_instance_count_incremental" {
  default = {
    development = "1"
    qa          = "1"
    integration = "1"
    preprod     = "2"
    production  = "2"
  }
}

variable "spark_kyro_buffer" {
  default = {
    development = "128m"
    qa          = "128m"
    integration = "128m"
    preprod     = "2047m"
    production  = "2047m" # Max amount allowed
  }
}

variable "spark_executor_instances" {
  default = {
    development = 50
    qa          = 50
    integration = 50
    preprod     = 116
    production  = 600 # More than possible as it won't create them if no core or memory available
  }
}

variable "emr_ami_id" {
  description = "AMI ID to use for the EMR nodes"
  default     = "ami-088b0a83763e28809"
}


variable "metadata_store_ch_writer_username" {
  description = "Username for metadata store write RDS user"
  default     = "ch-writer"
}

variable "emr_launcher_zip" {
  type = map(string)
  default = {
    base_path = "../emr-launcher-release"
    version   = "1.0.36"
  }
}
