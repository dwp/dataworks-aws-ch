resource "aws_acm_certificate" "ch_cert" {
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
