resource "aws_iam_instance_profile" "ch_instance_profile" {
  name = "ch_instance_profile"
  role = aws_iam_role.ch_role_for_instance_profile.id
}

resource "aws_iam_role" "ch_role_for_instance_profile" {
  name               = "ch_role_for_instance_profile"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = merge(
    local.common_tags,
    {
      "Name" = "ch_role_for_instance_profile"
    },
  )
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

data "aws_iam_policy_document" "publish_to_ch_trigger_topic" {
  statement {
    sid     = "TriggerchSNS"
    actions = ["SNS:Publish"]
    effect  = "Allow"

    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
    resources = [aws_sns_topic.trigger_ch_sns.arn]
  }
}


data "aws_iam_policy_document" "publish_to_ch_trigger" {
  statement {
    sid    = "AllowAccessToSNSLauncherTopic"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.trigger_ch_sns.arn
    ]
  }
}

data "aws_iam_policy_document" "get_ch_cert" {
  statement {
    effect = "Allow"

    actions = [
      "acm:ExportCertificate",
    ]

    resources = [
      aws_acm_certificate.ch_cert.arn
    ]
  }
}
resource "aws_iam_policy" "get_ch_cert" {
  name        = "ACMExportCH"
  description = "Allow export of ch certificate"
  policy      = data.aws_iam_policy_document.get_ch_cert.json
}

resource "aws_iam_role_policy_attachment" "get_ch_cert" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.get_ch_cert.arn
}

resource "aws_iam_role" "ch_emr_service" {
  name               = "ch_emr_service"
  assume_role_policy = data.aws_iam_policy_document.emr_assume_role.json
  tags = merge(
    local.common_tags,
    {
      "Name" = "ch_service_role"
    },
  )
}

data "aws_iam_policy_document" "emr_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "emr_capacity_reservations" {
  role       = aws_iam_role.ch_emr_service.name
  policy_arn = aws_iam_policy.emr_capacity_reservations.arn
}

resource "aws_iam_role_policy_attachment" "emr_attachment_old" {
  role       = aws_iam_role.ch_emr_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_policy" "emr_capacity_reservations" {
  name        = "CHCapacityReservations"
  description = "Allow usage of capacity reservations"
  policy      = data.aws_iam_policy_document.emr_capacity_reservations.json
}


data "aws_iam_policy_document" "emr_capacity_reservations" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateLaunchTemplateVersion"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeCapacityReservations"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "resource-groups:ListGroupResources"
    ]

    resources = ["*"]
  }
}


data "aws_iam_policy_document" "ch_ebs_cmk_encrypt" {
  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [aws_kms_key.ch_ebs_cmk.arn]
  }

  statement {
    effect = "Allow"

    actions = ["kms:CreateGrant"]

    resources = [aws_kms_key.ch_ebs_cmk.arn]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "ch_ebs_cmk_encrypt" {
  name        = "CHEbsCmkEncrypt"
  description = "Allow encryption and decryption using the CH EBS CMK"
  policy      = data.aws_iam_policy_document.ch_ebs_cmk_encrypt.json
}



data "aws_iam_policy_document" "ch_ebs_cmk" {
  statement {
    sid    = "EnableIAMPermissionsBreakglass"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.breakglass.arn]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsCI"
    effect = "Allow"

    principals {
      identifiers = [data.aws_iam_role.ci.arn]
      type        = "AWS"
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyCIEncryptDecrypt"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.ci.arn]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ImportKeyMaterial",
      "kms:ReEncryptFrom",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsAdministrator"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.administrator.arn]
    }

    actions = [
      "kms:Describe*",
      "kms:List*",
      "kms:Get*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EnableAWSConfigManagerScanForSecurityHubCH"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.aws_config.arn]
    }

    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsAnalyticDatasetGen"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ch_emr_service.arn, aws_iam_role.ch_role_for_instance_profile.arn]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

  }

  statement {
    sid    = "AllowCHServiceGrant"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ch_emr_service.arn, aws_iam_role.ch_role_for_instance_profile.arn]
    }

    actions = ["kms:CreateGrant"]

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}


resource "aws_iam_role" "ch_emr_launcher_lambda_role" {
  name               = "ch_emr_launcher_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.ch_emr_launcher_assume_policy.json
}

data "aws_iam_policy_document" "ch_emr_launcher_assume_policy" {
  statement {
    sid     = "CHEMRLauncherLambdaAssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}


data "aws_iam_policy_document" "ch_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.config_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.config_bucket_cmk.arn,
    ]
  }
}


resource "aws_iam_policy" "ch_read_config" {
  name        = "chReadConfig"
  description = "Allow reading of ch config files"
  policy      = data.aws_iam_policy_document.ch_read_config.json
}

resource "aws_iam_role_policy_attachment" "ch_read_config" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_read_config.arn
}

data "aws_iam_policy_document" "ch_emr_launcher_read_s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      format("arn:aws:s3:::%s/emr/dataworks-aws-ch/*", data.terraform_remote_state.common.outputs.config_bucket.id),
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
    ]
  }
}

data "aws_iam_policy_document" "ch_emr_launcher_runjobflow_policy" {
  statement {
    effect = "Allow"
    actions = [
      "elasticmapreduce:RunJobFlow",
      "elasticmapreduce:AddTags",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "ch_emr_launcher_pass_role_document" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::*:role/*"
    ]
  }
}

resource "aws_iam_policy" "ch_emr_launcher_read_s3_policy" {
  name        = "cHReadS3"
  description = "Allow cH to read from S3 bucket"
  policy      = data.aws_iam_policy_document.ch_emr_launcher_read_s3_policy.json
}

resource "aws_iam_policy" "ch_emr_launcher_runjobflow_policy" {
  name        = "cHRunJobFlow"
  description = "Allow ch to run job flow"
  policy      = data.aws_iam_policy_document.ch_emr_launcher_runjobflow_policy.json
}

resource "aws_iam_policy" "ch_emr_launcher_pass_role_policy" {
  name        = "cHPassRole"
  description = "Allow ch to pass role"
  policy      = data.aws_iam_policy_document.ch_emr_launcher_pass_role_document.json
}

resource "aws_iam_role_policy_attachment" "ch_emr_launcher_read_s3_attachment" {
  role       = aws_iam_role.ch_emr_launcher_lambda_role.name
  policy_arn = aws_iam_policy.ch_emr_launcher_read_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "ch_emr_launcher_runjobflow_attachment" {
  role       = aws_iam_role.ch_emr_launcher_lambda_role.name
  policy_arn = aws_iam_policy.ch_emr_launcher_runjobflow_policy.arn
}

resource "aws_iam_role_policy_attachment" "ch_emr_launcher_pass_role_attachment" {
  role       = aws_iam_role.ch_emr_launcher_lambda_role.name
  policy_arn = aws_iam_policy.ch_emr_launcher_pass_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "ch_emr_launcher_policy_execution" {
  role       = aws_iam_role.ch_emr_launcher_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "ch_emr_launcher_getsecrets" {
  name        = "ChGetSecrets"
  description = "Allow ch Lambda function to get secrets"
  policy      = data.aws_iam_policy_document.ch_emr_launcher_getsecrets.json
}

data "aws_iam_policy_document" "ch_emr_launcher_getsecrets" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
//      aws_secretsmanager_secret.metadata_store_ch_writer.arn, does this needs to be created?
      data.terraform_remote_state.internal_compute.outputs.metadata_store_users.ch_writer.secret_arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ch_emr_launcher_getsecrets" {
  role       = aws_iam_role.ch_emr_launcher_lambda_role.name
  policy_arn = aws_iam_policy.ch_emr_launcher_getsecrets.arn
}


data "aws_iam_policy_document" "ch_write_parquet" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.published_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
      "s3:DeleteObject*",
      "s3:PutObject*",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/data/uc_ch/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.published_bucket_cmk.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ch_write_parquet" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_write_parquet.arn
}

resource "aws_iam_policy" "ch_write_parquet" {
  name        = "CHWriteParquet"
  description = "Allow writing of CH parquet files to published"
  policy      = data.aws_iam_policy_document.ch_write_parquet.json
}

data "aws_iam_policy_document" "ch_data_ingress" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.data_ingress_stage_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:*Object*",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.data_ingress_stage_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.stage_data_ingress_bucket_cmk.arn
    ]
  }
}

resource "aws_iam_policy" "ch_data_ingress" {
  name        = "CHDataIngress"
  description = "Allow reading and writing to stage bucket"
  policy      = data.aws_iam_policy_document.ch_data_ingress.json
}

resource "aws_iam_role_policy_attachment" "ch_data_ingress" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_data_ingress.arn
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
  name        = "cHWriteLogs"
  description = "Allow writing of CH logs"
  policy      = data.aws_iam_policy_document.ch_write_logs.json
}

resource "aws_iam_role_policy_attachment" "ch_write_logs" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_write_logs.arn
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

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstanceStatus",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ds:CreateComputer",
      "ds:DescribeDirectories",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::eu-west-2.elasticmapreduce",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      "arn:aws:s3:::eu-west-2.elasticmapreduce/libs/script-runner/*",
    ]
  }
}

resource "aws_iam_policy" "ch_metadata_change" {
  name        = "CHMetadataOptions"
  description = "Allow editing of Metadata Options"
  policy      = data.aws_iam_policy_document.ch_metadata_change.json
}

resource "aws_iam_role_policy_attachment" "ch_instance_profile_role_metadata_change" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_metadata_change.arn
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "emr_attachment" {
  role       = aws_iam_role.ch_emr_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role_policy_attachment" "ch_emr_service_ebs_cmk" {
  role       = aws_iam_role.ch_emr_service.name
  policy_arn = aws_iam_policy.ch_ebs_cmk_encrypt.arn
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
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_read_artefacts.arn
}

data "aws_iam_policy_document" "ch_write_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:PutItem",
      "dynamodb:Scan",
      "dynamodb:GetRecords",
      "dynamodb:Query",
    ]

    resources = [
      data.terraform_remote_state.internal_compute.outputs.data_pipeline_metadata_dynamo.arn
    ]
  }
}

resource "aws_iam_policy" "ch_write_dynamodb" {
  name        = "ChDynamoDB"
  description = "Allows read and write access to ch's EMRFS DynamoDB table"
  policy      = data.aws_iam_policy_document.ch_write_dynamodb.json
}

resource "aws_iam_role_policy_attachment" "ch_dynamodb" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_write_dynamodb.arn
}


data "aws_iam_policy_document" "ch_events" {
  statement {
    effect = "Allow"
    actions = [
      "events:EnableRule",
      "events:PutRule",
      "events:PutTargets",
      "events:PutEvents",
      "events:ListRules",
      "events:DeleteRule",
      "events:ListTargetsByRule",
      "events:RemoveTargets",
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ch_events" {
  name        = "ChEvents"
  description = "Enable events to create alarms"
  policy      = data.aws_iam_policy_document.ch_events.json
}

resource "aws_iam_role_policy_attachment" "ch_events" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_events.arn
}
