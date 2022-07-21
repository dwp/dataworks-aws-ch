output "ch_acm_certificate_arn" {
  value = aws_acm_certificate.ch.arn
}

output "ch_trigger_topic_arn" {
  value = aws_sns_topic.trigger_ch_sns.arn
}

output "ch_ebs_kms_key_arn" {
  value = aws_kms_key.ch_ebs_cmk.arn
}

output "emr_security_conf_id" {
  value = aws_emr_security_configuration.ebs_emrfs_em.id
}

output "ch_adg_ebs_cmk" {
  value = aws_kms_key.ch_ebs_cmk
}
