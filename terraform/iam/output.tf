output "dw_ksr_s3_readonly_arn" {
  value = aws_iam_role.dw_ksr_s3_readonly.arn
}

output "ch_emr_service" {
  value = aws_iam_role.ch_emr_service
}

output "ch_instance_profile" {
  value = aws_iam_instance_profile.ch.arn
}

output "ch_emr_launcher_lambda_role_arn" {
  value = aws_iam_role.ch_emr_launcher_lambda_role.arn
}

output "ch_ebs_cmk_policy" {
  value = data.aws_iam_policy_document.ch_ebs_cmk.json
}

output "ch_publish_for_trigger_policy" {
  value = data.aws_iam_policy_document.ch_publish_for_trigger.json
}
