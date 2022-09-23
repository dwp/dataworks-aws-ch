resource "aws_s3_bucket_object" "steps_conf" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/steps/conf.tpl"
  content = templatefile("steps/conf.tpl",
    {
      aws_region_name     = var.region
      companies_s3_prexif = local.companies_s3_prefix
      partitioning_column = local.partitioning_column
      publish_bucket      = local.publish_bucket.id
      stage_bucket        = local.stage_bucket.id
      column_names        = local.column_names
      event_source        = local.event_source
    }
  )
}

resource "aws_s3_bucket_object" "e2e_conf" {
  bucket = local.config_bucket.id
  key    = "${local.ch_s3_prefix}/steps/e2e_test_conf.tpl"
  content = templatefile("tests/e2e_test_conf.tpl",
    {
      aws_region_name     = var.region
      publish_bucket      = local.publish_bucket.id
      partitioning_column = local.partitioning_column
      stage_bucket        = local.stage_bucket.id
      column_names        = local.column_names
      event_source        = local.event_source
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
  key    = "${local.ch_s3_prefix}/steps/e2e.py"
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
  key    = "${local.ch_s3_prefix}/tests/unit_test_conf.tpl"
  content = templatefile("tests/unit_test_conf.tpl",
    {
      partitioning_column = local.partitioning_column
      column_names        = local.column_names
    }
  )
}
