resource "aws_s3_bucket_object" "steps_conf" {
  bucket = var.data_config_bucket_id
  key    = "${var.local_ch_s3_prefix}/steps/conf.tpl"
  content = templatefile("steps/conf.tpl",
    {
      environment      = var.local_environment
      aws_region_name  = var.var_region
      publish_bucket = var.data_published_bucket_id
      url              = format("%s/datakey/actions/decrypt", var.data_dks_endpoint[var.local_environment])
      stage_bucket     = var.data_stage_bucket
    }
  )
}

resource "aws_s3_bucket_object" "etl" {
  bucket = var.data_config_bucket_id
  key    = "${var.local_ch_s3_prefix}/steps/etl.py"
  content = templatefile("steps/etl.py",
    {
    }
  )
}

resource "aws_s3_bucket_object" "e2e" {
  bucket = var.data_config_bucket_id
  key    = "${var.local_ch_s3_prefix}/tests/e2e.py"
  content = templatefile("tests/e2e.py",
    {
    }
  )
}

resource "aws_s3_bucket_object" "test_etl" {
  bucket = var.data_config_bucket_id
  key    = "${var.local_ch_s3_prefix}/tests/test_etl.py"
  content = templatefile("tests/test_etl.py",
    {
    }
  )
}

resource "aws_s3_bucket_object" "test_conf" {
  bucket = var.data_config_bucket_id
  key    = "${var.local_ch_s3_prefix}/tests/test_conf.tpl"
  content = templatefile("tests/test_conf.tpl",
    {
      environment      = var.local_environment
      aws_region_name  = var.var_region
      publish_bucket   = var.data_published_bucket_id
      url              = format("%s/datakey/actions/decrypt", var.data_dks_endpoint[var.local_environment])
      stage_bucket     = var.data_stage_bucket
    }
  )
}

