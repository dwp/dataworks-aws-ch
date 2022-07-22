resource "aws_cloudwatch_log_group" "ch_cw_agent_log_group" {
  name              = var.local_cw_agent_log_group_name
  retention_in_days = 180
  tags              = var.local_common_tags
}

resource "aws_cloudwatch_log_group" "ch_bootstrap_log_group" {
  name              = var.local_bootstrap_log_group_name
  retention_in_days = 180
  tags              = var.local_common_tags
}

resource "aws_cloudwatch_log_group" "ch_steps_log_group" {
  name              = var.local_steps_log_group_name
  retention_in_days = 180
  tags              = var.local_common_tags
}

resource "aws_cloudwatch_log_group" "ch_yarn_spark_log_group" {
  name              = var.local_yarn_spark_log_group_name
  retention_in_days = 180
  tags              = var.local_common_tags
}

resource "aws_cloudwatch_log_group" "ch_cw_e2e_log_group" {
  name              = var.local_e2e_log_group_name
  retention_in_days = 180
  tags              = var.local_common_tags
}
