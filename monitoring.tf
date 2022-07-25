resource "aws_cloudwatch_event_rule" "ch_terminated_with_errors_rule" {
  name          = "ch_terminated_with_errors_rule"
  description   = "Sends failed message to slack when ch cluster terminates with errors"
  event_pattern = <<EOF
{
  "source": [
    "aws.emr"
  ],
  "detail-type": [
    "EMR Cluster State Change"
  ],
  "detail": {
    "state": [
      "TERMINATED_WITH_ERRORS"
    ],
    "name": [
      "ch"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_metric_alarm" "ch_failed_with_errors" {
  alarm_name                = "ch_failed_with_errors"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "TriggeredRules"
  namespace                 = "AWS/Events"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors cluster termination with errors"
  insufficient_data_actions = []
  alarm_actions             = [local.monitoring_topic_arn]
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.ch_terminated_with_errors_rule.name
  }
  tags = merge(
    local.common_repo_tags,
    {
      Name              = "ch_failed_with_errors",
      notification_type = "Error"
      severity          = "Critical"
    },
  )
}

resource "aws_cloudwatch_event_rule" "ch_success" {
  name          = "ch_success"
  description   = "checks that all steps complete"
  event_pattern = <<EOF
{
  "source": [
    "aws.emr"
  ],
  "detail-type": [
    "EMR Cluster State Change"
  ],
  "detail": {
    "state": [
      "TERMINATED"
    ],
    "name": [
      "ch"
    ],
    "stateChangeReason": [
      "{\"code\":\"ALL_STEPS_COMPLETED\",\"message\":\"Steps completed\"}"
    ]
  }
}
EOF
}


resource "aws_cloudwatch_metric_alarm" "ch_success" {
  alarm_name                = "ch_completed_all_steps"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "TriggeredRules"
  namespace                 = "AWS/Events"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "Monitoring ch completion"
  insufficient_data_actions = []
  alarm_actions             = [local.monitoring_topic_arn]
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.ch_success.name
  }
  tags = merge(
    local.common_repo_tags,
    {
      Name              = "ch_completed_all_steps",
      notification_type = "Information",
      severity          = "Critical"
    },
  )
}

resource "aws_cloudwatch_event_rule" "ch_step_error_rule" {
  count         = length(local.steps)
  name          = format("%s_%s_%s", "ch_step", element(local.steps, count.index), "failed_rule")
  description   = "Sends failed message to slack when ch cluster step fails"
  event_pattern = <<EOF
{
  "source": [
    "aws.emr"
  ],
  "detail-type": [
    "EMR Step Status Change"
  ],
  "detail": {
    "state": [
      "FAILED"
    ],
    "name": [
      "${element(local.steps, count.index)}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_metric_alarm" "ch_step_error" {
  count                     = length(local.steps)
  alarm_name                = format("%s_%s_%s", "ch_step", element(local.steps, count.index), "failed")
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "TriggeredRules"
  namespace                 = "AWS/Events"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors cluster step errors"
  insufficient_data_actions = []
  alarm_actions             = [local.monitoring_topic_arn]
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.ch_step_error_rule[count.index].name
  }
  tags = merge(
    local.common_repo_tags,
    {
      Name              = "ch_step_failed",
      notification_type = "Error"
      severity          = "Critical"
    },
  )
}
