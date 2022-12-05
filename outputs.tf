output "ch_common_sg" {
  value = {
    id = aws_security_group.ch_common.id
  }
}

output "ch_launcher_lambda" {
  value = aws_lambda_function.ch_emr_launcher
}
