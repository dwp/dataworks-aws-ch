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

resource "aws_cloudwatch_event_rule" "every_month" {
    name = "every-month"
    count = local.environment == "production" ? 1 : 0
    description = "Fires every month"
    schedule_expression = "cron(30 8 5 * ? *)"
}

resource "aws_cloudwatch_event_target" "every_month" {
    rule = aws_cloudwatch_event_rule.every_month[0].name
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
    source_arn = aws_cloudwatch_event_rule.every_month[0].arn
}