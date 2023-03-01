resource "aws_lambda_function" "ch_emr_launcher" {
  filename      = "${var.emr_launcher_zip["base_path"]}/emr-launcher-${var.emr_launcher_zip["version"]}.zip"
  function_name = "ch_emr_launcher"
  role          = aws_iam_role.ch_emr_launcher_lambda_role.arn
  handler       = "emr_launcher/handler.handler"
  runtime       = "python3.7"
  source_code_hash = filebase64sha256(
    format(
      "%s/emr-launcher-%s.zip",
      var.emr_launcher_zip["base_path"],
      var.emr_launcher_zip["version"]
    )
  )
  publish = false
  timeout = 60
  environment {
    variables = {
      EMR_LAUNCHER_CONFIG_S3_BUCKET = local.config_bucket.id
      EMR_LAUNCHER_CONFIG_S3_FOLDER = "emr/dataworks-aws-ch"
      EMR_LAUNCHER_LOG_LEVEL        = "DEBUG"
    }
  }
}

//resource "aws_sns_topic_subscription" "trigger_ch" {
//  topic_arn = aws_sns_topic.trigger_ch_sns.arn
//  protocol  = "lambda"
//  endpoint  = aws_lambda_function.ch_emr_launcher.arn
//}
//
//resource "aws_lambda_permission" "ch_emr_launcher_subscription" {
//  statement_id  = "TriggerCHProcess"
//  action        = "lambda:InvokeFunction"
//  function_name = aws_lambda_function.ch_emr_launcher.function_name
//  principal     = "sns.amazonaws.com"
//  source_arn    = aws_sns_topic.trigger_ch_sns.arn
//}
//

resource "aws_cloudwatch_event_rule" "every_month" {
    name = "every-month"
    description = "Fires every month"
    schedule_expression = "cron(48 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "every_month" {
    rule = aws_cloudwatch_event_rule.every_month.name
    arn = aws_lambda_function.ch_emr_launcher.arn
    target_id = "lambdaCHtriggerTarget"
    input = <<JSON
    {
        "s3_overrides": null,
        "extend": null,
        "additional_step_args": null
    }
    JSON
}


resource "aws_lambda_permission" "every_month" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.ch_emr_launcher.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_month.arn
}