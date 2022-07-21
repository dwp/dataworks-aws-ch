resource "aws_iam_policy" "ch_cross_acct_policy" {

  name        = "ch_cross_acc_assume_role"
  description = "This policy gives access to ch_s3_readonly role to assume cross account role. Please note this policy can only be used by ch_s3_readonly role to gain access, as other account has only trusted ch_s3_readonly role to establish the connectivity from dataworks"
  policy      = data.aws_iam_policy_document.ch_cross_acc_policy.json
}

resource "aws_iam_role" "dw_ksr_s3_readonly" {
  name               = "ch_s3_readonly"
  description        = "This is an IAM role which assumes role from UC side to gain temporary read access on S3 bucket for ch data"
  assume_role_policy = data.aws_iam_policy_document.dw_ksr_assume_role.json
  tags               = var.local_common_tags
}

resource "aws_iam_role_policy_attachment" "ch_cross_acct_attachment" {
  role       = aws_iam_role.dw_ksr_s3_readonly.name
  policy_arn = aws_iam_policy.ch_cross_acct_policy.arn
}

data "aws_iam_policy_document" "ch_cross_acc_policy" {
  statement {
    sid     = "chCrossAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = flatten([
      #change the value whether to run in where to run the code
      var.local_environment == "development" || var.local_environment == "qa" || var.local_environment == "preprod" || var.local_environment == "production" ?
      flatten([
        format("arn:aws:iam::%s:role/%s", var.local_source_acc_nos[var.local_vacancies_environment_mapping[var.local_environment]], var.local_vacancies_assume_iam_role[var.local_environment]),
        format("arn:aws:iam::%s:role/%s", var.local_applications_source_acc_nos[var.local_applications_environment_mapping[var.local_environment]], var.local_application_assume_iam_role[var.local_environment]),
      ]) :
      [format("arn:aws:iam::%s:role/%s", var.local_source_acc_nos[var.local_vacancies_environment_mapping[var.local_environment]], var.local_vacancies_assume_iam_role[var.local_environment]), ]
    ])
  }
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
  name        = "ACMExportchDatasetGeneratorCert"
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

data "aws_iam_policy_document" "ch_dataset_generator_write_data" {
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

data "aws_iam_policy_document" "ch_secretsmanager" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      var.ch_secret.arn,
    ]
  }
}

data "aws_iam_policy_document" "ch_assume_role_policy" {
  statement {
    sid       = "ChCrossAccountAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/ch_s3_readonly"]
  }

}

resource "aws_iam_policy" "ch_assume_role_policy" {

  name        = "ch_assume_role"
  description = "This policy gives access to assume role on ch_s3_readonly role."
  policy      = data.aws_iam_policy_document.ch_assume_role_policy.json
}

resource "aws_iam_policy" "ch_secretsmanager" {
  name        = "ChSecretsManager"
  description = "Allow reading of ch config values"
  policy      = data.aws_iam_policy_document.ch_secretsmanager.json
}

resource "aws_iam_role" "ch" {
  name               = "ch"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.local_common_tags
}

resource "aws_iam_instance_profile" "ch" {
  name = "ch_jobflow_role"
  role = aws_iam_role.ch.id
}

resource "aws_iam_role_policy_attachment" "ch_assume_role_attachment" {
  role       = aws_iam_role.ch_emr_service.name
  policy_arn = aws_iam_policy.ch_assume_role_policy.arn
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

resource "aws_iam_role_policy_attachment" "emr_ch_secretsmanager" {
  role       = aws_iam_role.ch.name
  policy_arn = aws_iam_policy.ch_secretsmanager.arn
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
      "${var.data_logstore_bucket_arn}/${var.local_s3_log_prefix}",
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
      var.data_artefact_bucket.cmk_arn,
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
      "arn:aws:dynamodb:${var.var_region}:${var.local_account[var.local_environment]}:table/${var.data_audit_table_name}"
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
      "arn:aws:ec2:${var.var_region}:${var.local_account[var.local_environment]}:instance/*",
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

    resources = [
      var.data_sns_monitoring_topic_arn
    ]
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
    resources = [var.ch_trigger_topic_arn]
  }
}
