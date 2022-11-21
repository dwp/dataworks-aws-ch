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

resource "aws_iam_role_policy_attachment" "ch_emr_service_ebs_cmk" {
  role       = aws_iam_role.ch_emr_service.name
  policy_arn = aws_iam_policy.ch_ebs_cmk_encrypt.arn
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
      "kms:Encrypt",
      "kms:Decrypt",
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

data "aws_iam_policy_document" "ch_emr_launcher_read_s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      format("arn:aws:s3:::%s/emr/dataworks-aws-ch/*", data.terraform_remote_state.common.outputs.config_bucket.id)
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
      data.terraform_remote_state.common.outputs.data_ingress_stage_bucket.arn,
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
      data.terraform_remote_state.common.outputs.data_ingress_stage_bucket.arn
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
      data.terraform_remote_state.common.outputs.stage_data_ingress_bucket_cmk.arn
    ]
  }
}

resource "aws_iam_policy" "ch_write_parquet" {
  name        = "CHWriteParquet"
  description = "Allow writing of CH parquet files"
  policy      = data.aws_iam_policy_document.ch_write_parquet.json
}


data "aws_iam_policy_document" "ch_metadata_change" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:*Tags",
    ]

    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${local.account[local.environment]}:instance/*",
    ]
  }
}

resource "aws_iam_policy" "ch_metadata_change" {
  name        = "CHMetadataOptions"
  description = "Allow editing of Metadata Options"
  policy      = data.aws_iam_policy_document.ch_metadata_change.json
}

resource "aws_iam_role_policy_attachment" "analytical_dataset_generator_metadata_change" {
  role       = aws_iam_role.ch_role_for_instance_profile.name
  policy_arn = aws_iam_policy.ch_metadata_change.arn
}
