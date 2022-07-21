resource "aws_lambda_function" "ch_emr_launcher" {
  filename      = "${var.emr_launcher_zip["base_path"]}/emr-launcher-${var.emr_launcher_zip["version"]}.zip"
  function_name = "ch_emr_launcher"
  role          = var.ch_emr_launcher_lambda_role_arn
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
      EMR_LAUNCHER_CONFIG_S3_BUCKET = var.data_config_bucket.id
      EMR_LAUNCHER_CONFIG_S3_FOLDER = "emr/ch"
      EMR_LAUNCHER_LOG_LEVEL        = "debug"
    }
  }
}

resource "aws_sns_topic_subscription" "trigger_ch" {
  topic_arn = aws_sns_topic.trigger_ch_sns.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ch_emr_launcher.arn
}

resource "aws_lambda_permission" "ch_emr_launcher_subscription" {
  statement_id  = "TriggerCHProcess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ch_emr_launcher.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.trigger_ch_sns.arn
}

resource "aws_kms_key" "ch_ebs_cmk" {
  description             = "Encrypts ch EBS volumes"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = var.ch_ebs_cmk_policy

  tags = merge(
    var.local_common_tags,
    {
      Name                  = "ch_ebs_cmk"
      ProtectsSensitiveData = "True"
    }
  )
}

resource "aws_kms_alias" "ch_ebs_cmk" {
  name          = "alias/ch_ebs_cmk"
  target_key_id = aws_kms_key.ch_ebs_cmk.key_id
}

resource "aws_sns_topic" "trigger_ch_sns" {
  name = "trigger_ch_process"

  tags = merge(
    var.local_common_tags,
    {
      "Name" = "trigger_ch_sns"
    },
  )
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.trigger_ch_sns.arn
  policy = var.ch_publish_for_trigger_policy
}

data "aws_secretsmanager_secret_version" "terraform_secrets" {
  provider  = aws.management_dns
  secret_id = "/concourse/dataworks/terraform"
}

resource "aws_kms_key" "ch_ebs_cmk" {
  description             = "Encrypts ch EBS volumes"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = var.ch_ebs_cmk_policy
  tags = merge(
    var.local_common_tags,
    {
      Name                  = "ch_ebs_cmk"
      ProtectsSensitiveData = "True"
    }
  )
}
