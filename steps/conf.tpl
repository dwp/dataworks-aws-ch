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
event_bus : ${event_bus}
[audit-table]
name : data_pipeline_metadata
hash_key : Correlation_Id
range_key : DataProduct
data_product_name : CH
hash_id : dataworks-aws-ch
[file-size]
min : 2
max : 5
delta_min : -0.5
delta_max : 0.5
