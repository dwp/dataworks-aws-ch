data "aws_iam_policy_document" "ch_acm" {
  statement {
    effect = "Allow"
    actions = [
      "acm:*",
    ]
    resources = ["*"]
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
      "s3:*",
    ]
    resources = [
      "*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    resources = [
      "*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ds:*"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:*"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:*"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticmapreduce:*"
    ]
    resources = [
      "*",
    ]
  }
}


resource "aws_iam_policy" "ch_write_data" {
  name        = "chWriteData"
  description = "Allow writing of ch files"
  policy      = data.aws_iam_policy_document.ch_write_data.json
}



resource "aws_iam_role" "ch" {
  lifecycle { ignore_changes = [tags] }
  name               = "ch"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = merge(
    local.common_tags,
    {
      Name = "ch_role"
    }
  )
}

resource "aws_iam_instance_profile" "ch" {
  name = "jobflow"
  role = aws_iam_role.ch.arn
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


data "aws_iam_policy_document" "ch_read_bucket_and_tag" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:*",
    ]

    resources = [
      "*",
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


data "aws_iam_policy_document" "ch_write_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*",
    ]
    resources = [
      "*"
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
      "sns:*"
    ]

    effect = "Allow"

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ch_events" {
  statement {
    effect = "Allow"

    actions = [
      "events:*",
    ]
    resources = ["*"]
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
