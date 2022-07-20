[vars]
environment : test_env
aws_region : eu-west-2
assume_role_encrypted_acct_arn : test_assume_role_application_acct_arn
assume_role_unencrypted_acct_arn : test_assume_role_vacancy_acct_arn
assume_role_within_acct_arn : test_assume_role_within_acct_arn
s3_published_bucket : published-bucket-123
log_path : /var/log/kickstart_adg/generate-analytical-dataset.log
e2e_log_path: /var/log/kickstart_adg/e2e-tests.log
url : url_test
domain_name : uc_kickstart
e2e_test_folder : kickstart-e2e-tests
aws_secret_name : /kickstart/adg
DATABASE : uc_kickstart_test
PROCESSING_DT_MIN_DELTA:2021-06-02
PROCESSING_DT_MIN_INCREMENTAL:2021-06-28
VACANCY_DELTA_CORRELATION_ID : kickstart_vacancy_analytical_dataset_generation_delta
VACANCY_INCREMENTAL_CORRELATION_ID : kickstart_vacancy_analytical_dataset_generation_incremental
[audit-table]
name : test_table_name
hash_key : Correlation_Id
range_key : DataProduct
data_product_name : KICKSTART-ADG
