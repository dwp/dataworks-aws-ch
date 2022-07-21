output "cw_agent_log_group_name" {
  value = aws_cloudwatch_log_group.ch_cw_agent_log_group.name
}

output "bootstrap_log_group_name" {
  value = aws_cloudwatch_log_group.ch_bootstrap_log_group.name
}

output "steps_log_group_name" {
  value = aws_cloudwatch_log_group.ch_steps_log_group.name
}

output "ch_yarn_spark_log_group_name" {
  value = aws_cloudwatch_log_group.ch_yarn_spark_log_group.name
}

output "e2e_log_group_name" {
  value = aws_cloudwatch_log_group.ch_cw_e2e_log_group.name
}
