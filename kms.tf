
resource "aws_kms_key" "ch_ebs_cmk" {
  description             = "Encrypts ch EBS volumes"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = var.ch_ebs_cmk_policy

  tags = merge(
    var.local_common_tags,
    {
      Name                  = "ch_ebs_cmk"
      ProtectsSensitiveData = "True"
    }
  )
}

resource "aws_kms_alias" "ch_ebs_cmk" {
  name          = "alias/ch_ebs_cmk"
  target_key_id = aws_kms_key.ch_ebs_cmk.key_id
}
