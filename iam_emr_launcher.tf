
resource "aws_iam_role" "ch_emr_launcher_lambda_role" {
  name               = "ch_emr_launcher_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.ch_emr_launcher_assume_policy.json
}

data "aws_iam_policy_document" "ch_emr_launcher_assume_policy" {
  statement {
    sid     = "chEMRLauncherLambdaAssumeRolePolicy"
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
      format("arn:aws:s3:::%s/emr/ch/*", var.data_config_bucket_id)
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      var.data_config_bucket_cmk_arn
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
  name        = "chReadS3"
  description = "Allow ch to read from S3 bucket"
  policy      = data.aws_iam_policy_document.ch_emr_launcher_read_s3_policy.json
}

resource "aws_iam_policy" "ch_emr_launcher_runjobflow_policy" {
  name        = "chRunJobFlow"
  description = "Allow ch to run job flow"
  policy      = data.aws_iam_policy_document.ch_emr_launcher_runjobflow_policy.json
}

resource "aws_iam_policy" "ch_emr_launcher_pass_role_policy" {
  name        = "chPassRole"
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
