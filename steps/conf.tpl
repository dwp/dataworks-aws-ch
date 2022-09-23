[args]
region : ${aws_region_name}
destination_bucket : ${publish_bucket}
source_bucket : ${stage_bucket}
destination_prefix : ${companies_s3_prexif}
db_name: uc_ch
table_name : companies
log_path : /var/log/dataworks-aws-ch/etl.log
source_prefix : data-ingress/companies
filename : BasicCompanyData
partitioning_column : ${partitioning_column}
cols : ${column_names}
[audit-table]
name : data_pipeline_metadata
hash_key : Correlation_Id
range_key : DataProduct
data_product_name : CH
hash_id : dataworks-aws-ch
event_bus_arn : ${event_bus_arn}
