resource "aws_acm_certificate" "ch" {
  certificate_authority_arn = data.terraform_remote_state.aws_certificate_authority.outputs.root_ca.arn
  domain_name               = "ch.${local.env_prefix[local.environment]}${local.dataworks_domain_name}"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}

resource "aws_emr_security_configuration" "ebs_emrfs_em" {
  name          = "ch_ebs_emrfs"
  configuration = jsonencode(local.ebs_emrfs_em)
}

resource "aws_sns_topic" "trigger_ch_sns" {
  name = "trigger_ch_process"

  tags = merge(
    local.common_repo_tags,
    {
      "Name" = "trigger_ch_sns"
    },
  )
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.trigger_ch_sns.arn
  policy = data.aws_iam_policy_document.ch_publish_for_trigger.json
}

//data "aws_secretsmanager_secret_version" "terraform_secrets" {
//  provider  = aws.management_dns
//  secret_id = "/concourse/dataworks/terraform"
//}
