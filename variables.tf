variable "truststore_aliases" {
  description = "comma seperated truststore aliases"
  type        = list(string)
  default     = ["dataworks_root_ca", "dataworks_mgt_root_ca"]
}

variable "emr_release" {
  default = {
    development = "6.3.0"
    qa          = "6.3.0"
    integration = "6.3.0"
    preprod     = "6.3.0"
    production  = "6.3.0"
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

variable "emr_core_instance_count" {
  default = {
    development = "5"
    qa          = "5"
    integration = "5"
    preprod     = "5"
    production  = "5"
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
    development = 25
    qa          = 25
    integration = 25
    preprod     = 25
    production  = 25
  }
}

variable "emr_ami_id" {
  description = "AMI ID to use for the EMR nodes"
}


variable "metadata_store_ch_writer_username" {
  description = "Username for metadata store write RDS user"
  default     = "ch-writer"
}


variable "emr_launcher_zip" {
  type = map(string)
  default = {
    base_path = "../emr-launcher-release"
    version   = "1.0.41"
  }
}
