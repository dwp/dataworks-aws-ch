resource "aws_cloudwatch_log_group" "ch_cw_agent_log_group" {
  name              = local.cw_agent_log_group_name
  retention_in_days = 180
  tags = {
    Name = "cw_agent"
  }
}

resource "aws_cloudwatch_log_group" "ch_bootstrap_log_group" {
  name              = local.bootstrap_log_group_name
  retention_in_days = 180
  tags = {
    Name = "bootstrap"
  }
}

resource "aws_cloudwatch_log_group" "ch_steps_log_group" {
  name              = local.steps_log_group_name
  retention_in_days = 180
  tags = {
    Name = "steps"
  }
}

resource "aws_cloudwatch_log_group" "ch_yarn_spark_log_group" {
  name              = local.yarn_spark_log_group_name
  retention_in_days = 180
  tags = {
    Name = "spark_yarn"
  }
}

resource "aws_cloudwatch_log_group" "ch_cw_e2e_log_group" {
  name              = local.e2e_log_group_name
  retention_in_days = 180
  tags = {
    Name = "e2e"
  }
}
