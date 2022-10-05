
data "aws_iam_policy_document" "ch_acm" {
  statement {
    effect = "Allow"

    actions = [
      "acm:ExportCertificate",
    ]

    resources = [aws_acm_certificate.ch.arn]
  }
}

resource "aws_iam_policy" "ch_acm" {
  name        = "ACMExportchCert"
  description = "Allow export of ch certificate"
  policy      = data.aws_iam_policy_document.ch_acm.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ch_write_data" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      local.publish_bucket.arn,
      format("arn:aws:s3:::%s/*", local.stage_bucket.id)
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:DeleteObject",
      "s3:Put*",
    ]

    resources = [
      "${local.publish_bucket.arn}/data/uc_ch/*",
      format("arn:aws:s3:::%s/e2e/*", local.stage_bucket.id)
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = [
      data.terraform_remote_state.common.outputs.published_bucket_cmk.arn,
      data.terraform_remote_state.common.outputs.stage_data_ingress_bucket_cmk.arn

    ]
  }
}

resource "aws_iam_policy" "ch_write_data" {
  name        = "chWriteData"
  description = "Allow writing of ch files"
  policy      = data.aws_iam_policy_document.ch_write_data.json
}



resource "aws_iam_role" "ch" {
  lifecycle {ignore_changes = [tags]}
  name               = "ch"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = merge(
    local.common_repo_tags,
    {
      Name = "ch_role"
    }
  )
}

resource "aws_iam_instance_profile" "ch" {
  name = "ch_jobflow_role"
  role = aws_iam_role.ch.id
}


resource "aws_iam_role_policy_attachment" "ec2_for_ssm_attachment" {
  role       = aws_iam_role.ch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  role       = aws_iam_role.ch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ch_ebs_cmk" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_ebs_cmk_encrypt.arn
}

resource "aws_iam_role_policy_attachment" "ch_write_data" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_write_data.arn
}

resource "aws_iam_role_policy_attachment" "ch_acm" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_acm.arn
}

data "aws_iam_policy_document" "ch_write_logs" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.security-tools.outputs.logstore_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
      "s3:PutObject*",

    ]

    resources = [
      "${data.terraform_remote_state.security-tools.outputs.logstore_bucket.arn}/${local.s3_log_prefix}",
    ]
  }
}

resource "aws_iam_policy" "ch_write_logs" {
  name        = "chWriteLogs"
  description = "Allow writing of ch logs"
  policy      = data.aws_iam_policy_document.ch_write_logs.json
}

resource "aws_iam_role_policy_attachment" "ch_write_logs" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_write_logs.arn
}

data "aws_iam_policy_document" "ch_read_bucket_and_tag" {

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [format("arn:aws:s3:::%s/emr/dataworks-aws-ch/*", local.config_bucket.id),
    format("arn:aws:s3:::%s/*", local.stage_bucket.id)]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObjectTagging",
    ]
    resources = [format("arn:aws:s3:::%s/*", local.stage_bucket.id)]
  }


  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
    ]
  }
}

resource "aws_iam_policy" "ch_read_bucket_and_tag" {
  name        = "ReadBktAndTag"
  description = "Allow reading of ch config files"
  policy      = data.aws_iam_policy_document.ch_read_bucket_and_tag.json
}

resource "aws_iam_role_policy_attachment" "ch_read_bucket_and_tag" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_read_bucket_and_tag.arn
}

data "aws_iam_policy_document" "ch_read_artefacts" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.management_artefact.outputs.artefact_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
    ]

    resources = [
      "${data.terraform_remote_state.management_artefact.outputs.artefact_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      data.terraform_remote_state.management_artefact.outputs.artefact_bucket.cmk_arn,
    ]
  }
}

resource "aws_iam_policy" "ch_read_artefacts" {
  name        = "chReadArtefacts"
  description = "Allow reading of ch software artefacts"
  policy      = data.aws_iam_policy_document.ch_read_artefacts.json
}

resource "aws_iam_role_policy_attachment" "ch_read_artefacts" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_read_artefacts.arn
}

data "aws_iam_policy_document" "ch_write_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${local.account[local.environment]}:table/${local.audit_table.name}"
    ]
    condition {
      test     = "ForAllValues:StringLike"
      variable = "dynamodb:LeadingKeys"
      values   = ["dataworks-aws-ch*"]
    }
  }
    statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Scan",
      "dynamodb:GetRecords",
      "dynamodb:Query",
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${local.account[local.environment]}:table/${local.audit_table.name}"
    ]
  }
}

resource "aws_iam_policy" "ch_write_dynamodb" {
  name        = "chDynamoDB"
  description = "Allows access to centralised DynamoDB table but can only modify ch items"
  policy      = data.aws_iam_policy_document.ch_write_dynamodb.json
}

resource "aws_iam_role_policy_attachment" "ch_dynamodb" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_write_dynamodb.arn
}

data "aws_iam_policy_document" "ch_metadata_change" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:*Tags",
    ]

    resources = [
      "arn:aws:ec2:${var.region}:${local.account[local.environment]}:instance/*",
    ]
  }
}

resource "aws_iam_policy" "ch_metadata_change" {
  name        = "chMetadataOptions"
  description = "Allow editing of Metadata Options"
  policy      = data.aws_iam_policy_document.ch_metadata_change.json
}

resource "aws_iam_role_policy_attachment" "ch_metadata_change" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_metadata_change.arn
}

resource "aws_iam_policy" "ch_sns_alerts" {
  name        = "chSnsAlerts"
  description = "Allow ch to send messages to monitoring topic"
  policy      = data.aws_iam_policy_document.ch_sns_topic_policy_for_alert.json
}

resource "aws_iam_role_policy_attachment" "ch_sns_alerts" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_sns_alerts.arn
}

data "aws_iam_policy_document" "ch_sns_topic_policy_for_alert" {
  statement {
    sid = "TriggerChSNS"

    actions = [
      "SNS:Publish"
    ]

    effect = "Allow"

    resources = [local.monitoring_topic_arn]
  }
}

data "aws_iam_policy_document" "ch_events" {
  statement {
    effect = "Allow"

    actions = [
      "events:*",
    ]

    resources = [
      aws_cloudwatch_event_rule.ch_started.arn, aws_cloudwatch_event_rule.ch_step_error_rule.arn,aws_cloudwatch_event_rule.ch_success.arn,
      aws_cloudwatch_event_rule.ch_terminated_with_errors_rule.arn, aws_cloudwatch_event_rule.delta_file_size_check_failed.arn, aws_cloudwatch_event_rule.file_size_check_failed.arn,
      aws_cloudwatch_event_rule.file_landed.arn,
      aws_cloudwatch_metric_alarm.ch_started.arn, aws_cloudwatch_metric_alarm.ch_step_error.arn,aws_cloudwatch_metric_alarm.ch_success.arn,
      aws_cloudwatch_metric_alarm.ch_failed_with_errors, aws_cloudwatch_metric_alarm.delta_file_size_check_failed.arn, aws_cloudwatch_metric_alarm.file_size_check_failed.arn,
      aws_cloudwatch_metric_alarm.file_landed.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
      "s3:PutObject*",

    ]

    resources = [
      "${data.terraform_remote_state.security-tools.outputs.logstore_bucket.arn}/${local.s3_log_prefix}",
    ]
  }
}

resource "aws_iam_policy" "ch_events" {
  name        = "chEvents"
  description = "Allow ch events"
  policy      = data.aws_iam_policy_document.ch_events.json
}

resource "aws_iam_role_policy_attachment" "ch_events" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_events.arn
}
