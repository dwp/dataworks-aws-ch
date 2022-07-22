[audit-table]
name : data_pipeline_metadata
hash_key : Correlation_Id
range_key : DataProduct
data_product_name : CH
hash_id : ch_companies
[args]
environment : ${environment}
aws_region : ${aws_region_name}
url : ${url}
publish_bucket : ${publish_bucket}
stage_bucket : ${stage_bucket}
destination_prefix : data/ch/companies
db_name: test_ch
table_name : companies
log_path : /var/log/ch/e2e-tests.log
e2e_log_path: /var/log/ch/e2e-tests.log
e2e_s3_prefix : e2e-ch/companies/
s3_prefix : ch/companies/
filename : BasicCompanyData
partitioning_column : uploaded_on_source
cols : ['CompanyName','CompanyNumber', 'RegAddress.CareOf', 'RegAddress.POBox', 'RegAddress.AddressLine1', 'RegAddress.AddressLine2',
'RegAddress.PostTown', 'RegAddress.County', 'RegAddress.Country', 'RegAddress.PostCode', 'CompanyCategory','CompanyStatus', 'CountryOfOrigin',
'DissolutionDate','IncorporationDate', 'Accounts.AccountRefDay','Accounts.AccountRefMonth', 'Accounts.NextDueDate','Accounts.LastMadeUpDate',
'Accounts.AccountCategory','Returns.NextDueDate', 'Returns.LastMadeUpDate','Mortgages.NumMortCharges', 'Mortgages.NumMortOutstanding',
'Mortgages.NumMortPartSatisfied', 'Mortgages.NumMortSatisfied','SICCode.SicText_1', 'SICCode.SicText_2', 'SICCode.SicText_3','SICCode.SicText_4',
'LimitedPartnerships.NumGenPartners','LimitedPartnerships.NumLimPartners', 'URI', 'PreviousName_1.CONDATE','PreviousName_1.CompanyName',
'PreviousName_2.CONDATE','PreviousName_2.CompanyName', 'PreviousName_3.CONDATE','PreviousName_3.CompanyName', 'PreviousName_4.CONDATE',
'PreviousName_4.CompanyName', 'PreviousName_5.CONDATE','PreviousName_5.CompanyName', 'PreviousName_6.CONDATE','PreviousName_6.CompanyName',
'PreviousName_7.CONDATE','PreviousName_7.CompanyName', 'PreviousName_8.CONDATE',' PreviousName_8.CompanyName', 'PreviousName_9.CONDATE',
'PreviousName_9.CompanyName', 'PreviousName_10.CONDATE','PreviousName_10.CompanyName', 'ConfStmtNextDueDate','ConfStmtLastMadeUpDate']
