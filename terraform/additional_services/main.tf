
resource "aws_acm_certificate" "ch" {
  certificate_authority_arn = var.root_certificate_authority_arn
  domain_name               = "ch.${var.local_env_prefix[var.local_environment]}${var.local_dataworks_domain_name}"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}

resource "aws_emr_security_configuration" "ebs_emrfs_em" {
  name          = "ch_ebs_emrfs"
  configuration = jsonencode(var.local_ebs_emrfs_em)
}


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

resource "aws_sns_topic" "trigger_ch_sns" {
  name = "trigger_ch_process"

  tags = merge(
    var.local_common_tags,
    {
      "Name" = "trigger_ch_sns"
    },
  )
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.trigger_ch_sns.arn
  policy = var.ch_publish_for_trigger_policy
}

//data "aws_secretsmanager_secret_version" "terraform_secrets" {
//  provider  = aws.management_dns
//  secret_id = "/concourse/dataworks/terraform"
//}
