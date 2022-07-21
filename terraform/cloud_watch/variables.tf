variable "local_common_tags" {
  description = "repository tags"
}

variable "data_sns_monitoring_topic_arn" {
  type        = string
  description = "monitoring topic arn"
}

variable "local_cw_agent_log_group_name" {
  type        = string
  description = "log group name for cw agent"
}

variable "local_bootstrap_log_group_name" {
  type        = string
  description = "cw log group name for bootstrap actions"
}

variable "local_steps_log_group_name" {
  type        = string
  description = "cw log group name for step"
}

variable "local_yarn_spark_log_group_name" {
  type        = string
  description = "cw log group name for yarn and spark logs"
}

variable "local_e2e_log_group_name" {
  type        = string
  description = "cw log group name for e2e tests"
}

variable "local_modules" {
  type        = list(any)
  description = "module names as they appear in the step scripts"
}

variable "local_metrics_namespace" {
  type        = string
  description = "namespace for ch metrics"
}

variable "var_steps_args" {
  description = "additional arguments to submit steps"
}

variable "local_environment" {
}

variable "ch_trigger_topic_arn" {
}
