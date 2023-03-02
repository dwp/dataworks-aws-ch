resource "aws_cloudwatch_event_rule" "every_month" {
    count = local.environment == "production" ? 1 : 0
    name = "every-month"
    description = "Fires every month"
    schedule_expression = "cron(30 8 5 * ? *)"
}

resource "aws_cloudwatch_event_target" "every_month" {
    count = local.environment == "production" ? 1 : 0
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
    count = local.environment == "production" ? 1 : 0
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.ch_emr_launcher.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_month[0].arn
}
