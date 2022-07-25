resource "aws_iam_role" "dw_ksr_s3_readonly" {
  name               = "ch_s3_readonly"
  description        = "This is an IAM role which assumes role from UC side to gain temporary read access on S3 bucket for ch data"
  assume_role_policy = data.aws_iam_policy_document.dw_ksr_assume_role.json
  tags               = local.common_repo_tags
}


data "aws_iam_policy_document" "ch_acm" {
  statement {
    effect = "Allow"

    actions = [
      "acm:ExportCertificate",
    ]

    resources = [var.ch_acm_certificate_arn]
  }
}

resource "aws_iam_policy" "ch_acm" {
  name        = "ACMExportchCert"
  description = "Allow export of Dataset Generator certificate"
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
      var.data_published_bucket_arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:DeleteObject*",
      "s3:Put*",
    ]

    resources = [
      "${var.data_published_bucket_arn}/data/uc_ch/*",
      "${var.data_published_bucket_arn}/ch/*",
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
      var.data_published_bucket_cmk
    ]
  }
}

resource "aws_iam_policy" "ch_write_data" {
  name        = "chWriteData"
  description = "Allow writing of ch files"
  policy      = data.aws_iam_policy_document.ch_write_data.json
}



resource "aws_iam_role" "ch" {
  name               = "ch"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_repo_tags
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
      var.data_logstore_bucket_arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
      "s3:PutObject*",

    ]

    resources = [
      "${var.data_logstore_bucket_arn}/${local.s3_log_prefix}",
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

data "aws_iam_policy_document" "ch_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      var.data_config_bucket_arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
    ]

    resources = [
      "${var.data_config_bucket_arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      var.data_config_bucket_cmk_arn,
    ]
  }
}

resource "aws_iam_policy" "ch_read_config" {
  name        = "chReadConfig"
  description = "Allow reading of ch config files"
  policy      = data.aws_iam_policy_document.ch_read_config.json
}

resource "aws_iam_role_policy_attachment" "ch_read_config" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_read_config.arn
}

data "aws_iam_policy_document" "ch_read_artefacts" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      var.data_artefact_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
    ]

    resources = [
      "${var.data_artefact_bucket.arn}/*",
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
      "dynamodb:*",
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${local.account[local.environment]}:table/${local.audit_table.name}"
    ]
  }
}

resource "aws_iam_policy" "ch_write_dynamodb" {
  name        = "chDynamoDB"
  description = "Allows read and write access to ch's EMRFS DynamoDB table"
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
  description = "Allow ch to publish SNS alerts"
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

data "aws_iam_policy_document" "dw_ksr_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [aws_iam_role.ch.arn,
      aws_iam_role.ch_emr_service.arn]
    }

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}


data "aws_iam_policy_document" "ch_publish_for_trigger" {
  statement {
    sid     = "TriggerChSNS"
    actions = ["SNS:Publish"]
    effect  = "Allow"

    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
    resources = []
  }
}
