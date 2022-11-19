
data "aws_iam_policy_document" "ch_ebs_cmk_s" {
  statement {
    sid    = "EnableIAMPermissionsCI"
    effect = "Allow"

    principals {
      identifiers = [data.aws_iam_role.ci.arn]
      type        = "AWS"
    }

    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsAdministrator"
    effect = "Allow"

    principals {
      identifiers = [data.aws_iam_role.administrator.arn]
      type        = "AWS"
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
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
    sid    = "EnableAWSConfigManagerScanForSecurityHub"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.aws_config.arn]
    }
    actions = [
      "kms:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EnableIAMPermissionsAnalyticDatasetGen"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.aws_ch_emr_service.arn, aws_iam_role.ch.arn]
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
      identifiers = [aws_iam_role.aws_ch_emr_service.arn, aws_iam_role.ch.arn]
    }
    actions   = ["kms:*"]
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
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = [aws_kms_key.ch_ebs_cmk.arn]
  }
}

resource "aws_iam_policy" "ch_ebs_cmk_encrypt" {
  lifecycle { ignore_changes = [tags] }
  name        = "chEbsCmkEncrypt"
  description = "Allow encryption and decryption using the ch EBS CMK"
  policy      = data.aws_iam_policy_document.ch_ebs_cmk_encrypt.json
}
