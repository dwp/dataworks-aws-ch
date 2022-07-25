resource "aws_s3_bucket_object" "steps_conf" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/steps/conf.tpl"
  content = templatefile("steps/conf.tpl",
    {
      environment     = local.environment
      aws_region_name = var.region
      publish_bucket  = local.publish_bucket.id
      url             = format("%s/datakey/actions/decrypt", local.dks_endpoint)
      stage_bucket    = local.stage_bucket.id
    }
  )
}

resource "aws_s3_bucket_object" "etl" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/steps/etl.py"
  content = templatefile("steps/etl.py",
    {
    }
  )
}

resource "aws_s3_bucket_object" "e2e" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/tests/e2e.py"
  content = templatefile("tests/e2e.py",
    {
    }
  )
}

resource "aws_s3_bucket_object" "test_etl" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/tests/test_etl.py"
  content = templatefile("tests/test_etl.py",
    {
    }
  )
}

resource "aws_s3_bucket_object" "test_conf" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/tests/test_conf.tpl"
  content = templatefile("tests/test_conf.tpl",
    {
      environment     = local.environment
      aws_region_name = var.region
      publish_bucket  = local.publish_bucket.id
      url             = format("%s/datakey/actions/decrypt", local.dks_endpoint)
      stage_bucket    = local.stage_bucket.id
    }
  )
}
