[audit-table]
name : data_pipeline_metadata
hash_key : Correlation_Id
range_key : DataProduct
data_product_name : CH
hash_id : dataworks-aws-ch-e2e
[args]
region : eu-west-2
destination_bucket : test-destination-bucket
source_bucket : test-source-bucket
db_name: test_db
table_name : test
filename : BasicCompanyData
partitioning_column : date_sent
cols : '[StructField('CompanyName', StringType(), True), StructField('CompanyNumber', StringType(), True), StructField('RegAddress.CareOf', StringType(), True)]'
log_path: /var/log/dataworks-aws-ch/e2e-tests.log
source_prefix : e2e/data-ingress/companies
destination_prefix : e2e/data/test_db/companies
