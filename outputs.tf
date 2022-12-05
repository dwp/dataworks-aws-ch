output "ch_common_sg" {
  value = {
    id = aws_security_group.ch_common.id
  }
}

output "ch_launcher_lambda_arn" {
  value = aws_lambda_function.ch_emr_launcher.arn
}
