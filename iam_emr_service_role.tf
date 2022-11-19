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

data "aws_iam_policy_document" "emr_capacity_reservations" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:*"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "resource-groups:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "aws_ch_emr_service" {
  name               = "aws_ch_emr_service"
  assume_role_policy = data.aws_iam_policy_document.emr_assume_role.json
  tags               = local.common_tags
}

# This is deprecated and needs a ticket to remove it
resource "aws_iam_role_policy_attachment" "emr_attachment_old" {
  role       = aws_iam_role.aws_ch_emr_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEMRServicePolicy_v2"
}

resource "aws_iam_policy" "emr_capacity_reservations" {
  name        = "aws_chCapacityReservations"
  description = "Allow usage of capacity reservations"
  policy      = data.aws_iam_policy_document.emr_capacity_reservations.json
}

resource "aws_iam_role_policy_attachment" "emr_capacity_reservations" {
  role       = aws_iam_role.aws_ch_emr_service.name
  policy_arn = aws_iam_policy.emr_capacity_reservations.arn
}

resource "aws_iam_role_policy_attachment" "aws_ch_emr_service_ebs_cmk" {
  role       = aws_iam_role.aws_ch_emr_service.name
  policy_arn = aws_iam_policy.ch_ebs_cmk_encrypt.arn
}
