output "ch_sg_common" {
  value = aws_security_group.ch_common.id
}

output "ch_sg_master" {
  value = aws_security_group.ch_master.id
}

output "ch_sg_slave" {
  value = aws_security_group.ch_slave.id
}

output "ch_sg_emr_service" {
  value = aws_security_group.ch_emr_service.id
}

output "ch_common_sg" {
  value = aws_security_group.ch_common.id
}
