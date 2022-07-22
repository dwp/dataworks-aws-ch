provider "aws" {
  alias = "aws"
}

provider "aws" {
  alias = "crypto"
}

resource "aws_security_group" "ch_master" {
  name                   = "ch Master"
  description            = "Contains rules for ch master nodes; most rules are injected by EMR, not managed by TF"
  revoke_rules_on_delete = true
  vpc_id                 = var.data_internal_compute_vpc_id
}

resource "aws_security_group" "ch_slave" {
  name                   = "ch Slave"
  description            = "Contains rules for ch slave nodes; most rules are injected by EMR, not managed by TF"
  revoke_rules_on_delete = true
  vpc_id                 = var.data_internal_compute_vpc_id
}

resource "aws_security_group" "ch_common" {
  name                   = "ch Common"
  description            = "Contains rules for both ch master and slave nodes"
  revoke_rules_on_delete = true
  vpc_id                 = var.data_internal_compute_vpc_id
}

resource "aws_security_group" "ch_emr_service" {
  name                   = "ch ADG EMR Service"
  description            = "Contains rules for ch EMR service when managing the ch cluster; rules are injected by EMR, not managed by TF"
  revoke_rules_on_delete = true
  vpc_id                 = var.data_internal_compute_vpc_id
}

resource "aws_security_group_rule" "egress_https_to_vpc_endpoints" {
  description              = "Allow HTTPS traffic to VPC endpoints"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ch_common.id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = var.data_vpc_interface_sg_id
}

resource "aws_security_group_rule" "ingress_https_vpc_endpoints_from_emr" {
  description              = "Allow HTTPS traffic from ch"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = var.data_vpc_interface_sg_id
  to_port                  = 443
  type                     = "ingress"
  source_security_group_id = aws_security_group.ch_common.id
}

resource "aws_security_group_rule" "egress_https_s3_endpoint" {
  description       = "Allow HTTPS access to S3 via its endpoint"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [var.data_vpc_prefix_list_ids.s3]
  security_group_id = aws_security_group.ch_common.id
}

resource "aws_security_group_rule" "egress_http_s3_endpoint" {
  description       = "Allow HTTP access to S3 via its endpoint (YUM)"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  prefix_list_ids   = [var.data_vpc_prefix_list_ids.s3]
  security_group_id = aws_security_group.ch_common.id
}

resource "aws_security_group_rule" "egress_https_dynamodb_endpoint" {
  description       = "Allow HTTPS access to DynamoDB via its endpoint (EMRFS)"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [var.data_vpc_prefix_list_ids.dynamodb]
  security_group_id = aws_security_group.ch_common.id
}

resource "aws_security_group_rule" "egress_internet_proxy" {
  description              = "Allow Internet access via the proxy (for ACM-PCA)"
  type                     = "egress"
  from_port                = 3128
  to_port                  = 3128
  protocol                 = "tcp"
  source_security_group_id = var.data_internet_proxy_sg
  security_group_id        = aws_security_group.ch_common.id
}

resource "aws_security_group_rule" "ingress_internet_proxy" {
  description              = "Allow proxy access from ch"
  type                     = "ingress"
  from_port                = 3128
  to_port                  = 3128
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ch_common.id
  security_group_id        = var.data_internet_proxy_sg
}

resource "aws_security_group_rule" "egress_to_dks" {
  description       = "Allow requests to the DKS"
  type              = "egress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = var.data_cidr_blocks
  security_group_id = aws_security_group.ch_common.id
}

resource "aws_security_group_rule" "ingress_to_dks" {
  provider          = aws.crypto
  description       = "Allow inbound requests to DKS from ch"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8443
  to_port           = 8443
  cidr_blocks       = var.data_ch_cidr_blocks
  security_group_id = var.data_dks_sg_id[var.local_environment]
}

# https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-man-sec-groups.html#emr-sg-elasticmapreduce-sa-private
resource "aws_security_group_rule" "emr_service_ingress_master" {
  description              = "Allow EMR master nodes to reach the EMR service"
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ch_master.id
  security_group_id        = aws_security_group.ch_emr_service.id
}


# The EMR service will automatically add the ingress equivalent of this rule,
# but doesn't inject this egress counterpart
resource "aws_security_group_rule" "emr_master_to_core_egress_tcp" {
  description              = "Allow master nodes to send TCP traffic to core nodes"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ch_slave.id
  security_group_id        = aws_security_group.ch_master.id
}

# The EMR service will automatically add the ingress equivalent of this rule,
# but doesn't inject this egress counterpart
resource "aws_security_group_rule" "emr_core_to_master_egress_tcp" {
  description              = "Allow core nodes to send TCP traffic to master nodes"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ch_master.id
  security_group_id        = aws_security_group.ch_slave.id
}

# The EMR service will automatically add the ingress equivalent of this rule,
# but doesn't inject this egress counterpart
resource "aws_security_group_rule" "emr_core_to_core_egress_tcp" {
  description       = "Allow core nodes to send TCP traffic to other core nodes"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.ch_slave.id
}

# The EMR service will automatically add the ingress equivalent of this rule,
# but doesn't inject this egress counterpart
resource "aws_security_group_rule" "emr_master_to_core_egress_udp" {
  description              = "Allow master nodes to send UDP traffic to core nodes"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  source_security_group_id = aws_security_group.ch_slave.id
  security_group_id        = aws_security_group.ch_master.id
}

# The EMR service will automatically add the ingress equivalent of this rule,
# but doesn't inject this egress counterpart
resource "aws_security_group_rule" "emr_core_to_master_egress_udp" {
  description              = "Allow core nodes to send UDP traffic to master nodes"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  source_security_group_id = aws_security_group.ch_master.id
  security_group_id        = aws_security_group.ch_slave.id
}

# The EMR service will automatically add the ingress equivalent of this rule,
# but doesn't inject this egress counterpart
resource "aws_security_group_rule" "emr_core_to_core_egress_udp" {
  description       = "Allow core nodes to send UDP traffic to other core nodes"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.ch_slave.id
}

resource "aws_security_group_rule" "ch_to_hive_metastore_v2" {
  description              = "ch to Hive Metastore v2"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ch_common.id
  security_group_id        = var.data_metastore_v2_sg_id
}

resource "aws_security_group_rule" "hive_metastore_v2_from_ch" {
  description              = "Hive Metastore v2  from ch"
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ch_common.id
  source_security_group_id = var.data_metastore_v2_sg_id
}
