variable "truststore_aliases" {
  description = "comma seperated truststore aliases"
  type        = list(string)
  default     = ["dataworks_root_ca", "dataworks_mgt_root_ca"]
}

variable "emr_release" {
  description = "Version of AWS EMR to deploy with associated applications"
  default = {
    development = "6.2.0"
    qa          = "6.2.0"
    integration = "6.2.0"
    preprod     = "6.2.0"
    production  = "6.2.0"
  }
}

variable "emr_ami_id" {
  description = "AMI ID to use for the EMR nodes"
  default     = "ami-050b863a496b98587"
}

variable "emr_instance_type" {
  default = {
    development = "m5.2xlarge"
    qa          = "m5.2xlarge"
    integration = "m5.2xlarge"
    preprod     = "m5.4xlarge"
    production  = "m5.4xlarge"
  }
}

variable "emr_core_instance_count" {
  default = {
    development = "1"
    qa          = "1"
    integration = "1"
    preprod     = "2"
    production  = "2"
  }
}


variable "num_cores_per_executor" {
  default = {
    development = "5"
    qa          = "5"
    integration = "5"
    preprod     = "5"
    production  = "5"
  }
}

variable "num_executors_per_node" {
  default = {
    development = "1"
    qa          = "1"
    integration = "1"
    preprod     = "1"
    production  = "1"
  }
}

variable "ram_memory_per_node" {
  default = {
    development = "32"
    qa          = "32"
    integration = "32"
    preprod     = "32"
    production  = "32"
  }
}

variable "emr_num_cores_per_core_instance" {
  default = {
    development = "8"
    qa          = "8"
    integration = "8"
    preprod     = "8"
    production  = "8"
  }
}

variable "spark_kyro_buffer" {
  default = {
    development = "128"
    qa          = "128"
    integration = "128"
    preprod     = "2047m"
    production  = "2047m"
  }
}

variable "emr_yarn_memory_gb_per_core_instance" {
  default = {
    development = "120"
    qa          = "120"
    integration = "120"
    preprod     = "184"
    production  = "184"
  }
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
