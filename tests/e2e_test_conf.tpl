[args]
region : ${aws_region_name}
source_bucket : ${stage_bucket}
db_name: test_ch
table_name : companies
filename : BasicCompanyData
partitioning_column : ${partitioning_column}
cols : ${column_names}
log_path: /var/log/dataworks-aws-ch/e2e-tests.log
source_prefix : e2e/data-ingress/companies
destination_prefix : e2e/data/test_ch/companies
destination_bucket : ${stage_bucket}
[audit-table]
name : data_pipeline_metadata
hash_key : Correlation_Id
range_key : DataProduct
data_product_name : CH
hash_id : dataworks-aws-ch-e2e
[file-size]
min : 0.02
max : 0.15
delta_min : -0.03
delta_max : 0.03
