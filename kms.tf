
resource "aws_kms_key" "ch_ebs_cmk" {
  description             = "Encrypts ch EBS volumes"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.ch_ebs_cmk_s.json

  tags = merge(
    local.common_repo_tags,
    {
      Name = "ch_ebs_cmk"
    }
  )
}

resource "aws_kms_alias" "ch_ebs_cmk" {
  name          = "alias/ch_ebs_cmk"
  target_key_id = aws_kms_key.ch_ebs_cmk.key_id
}
