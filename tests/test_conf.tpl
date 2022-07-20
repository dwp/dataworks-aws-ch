[audit-table]
name : data_pipeline_metadata
hash_key : Correlation_Id
range_key : DataProduct
data_product_name : CH
hash_id : ch-companies
[args]
environment : development
destination_prefix : data/ch/companies
region : eu-west-2
db_name: test_ch
table_name : companies
publish_bucket :
log_path : /var/log/kickstart_adg/e2e-tests.log
e2e_log_path: /var/log/kickstart_adg/e2e-tests.log
config_file_path: config.tpl
e2e_s3_prefix : e2e-ch/companies/
s3_prefix : e2e-ch/companies/
filename : BasicCompanyData
DATABASE : PLACEHOLDER_database
partitioning_column : UploadedOnSource
cols : ['CompanyName','CompanyNumber', 'RegAddress.CareOf', 'RegAddress.POBox', 'RegAddress.AddressLine1', 'RegAddress.AddressLine2', 'RegAddress.PostTown', 'RegAddress.County', 'RegAddress.Country', 'RegAddress.PostCode', 'CompanyCategory','CompanyStatus', 'CountryOfOrigin', 'DissolutionDate','IncorporationDate', 'Accounts.AccountRefDay','Accounts.AccountRefMonth', 'Accounts.NextDueDate','Accounts.LastMadeUpDate', 'Accounts.AccountCategory','Returns.NextDueDate', 'Returns.LastMadeUpDate','Mortgages.NumMortCharges', 'Mortgages.NumMortOutstanding','Mortgages.NumMortPartSatisfied', 'Mortgages.NumMortSatisfied','SICCode.SicText_1', 'SICCode.SicText_2', 'SICCode.SicText_3','SICCode.SicText_4', 'LimitedPartnerships.NumGenPartners','LimitedPartnerships.NumLimPartners', 'URI', 'PreviousName_1.CONDATE','PreviousName_1.CompanyName', 'PreviousName_2.CONDATE','PreviousName_2.CompanyName', 'PreviousName_3.CONDATE','PreviousName_3.CompanyName', 'PreviousName_4.CONDATE','PreviousName_4.CompanyName', 'PreviousName_5.CONDATE','PreviousName_5.CompanyName', 'PreviousName_6.CONDATE','PreviousName_6.CompanyName', 'PreviousName_7.CONDATE','PreviousName_7.CompanyName', 'PreviousName_8.CONDATE',' PreviousName_8.CompanyName', 'PreviousName_9.CONDATE','PreviousName_9.CompanyName', 'PreviousName_10.CONDATE','PreviousName_10.CompanyName', 'ConfStmtNextDueDate','ConfStmtLastMadeUpDate']
schema_account : ["reference_number", "balance_sheet_date", "context_reference", "name", "value"]
file_to_read : e2e-ch/accounts/Prod223_3071_00361854_20210331.html
file_modified : e2e-ch/output/accounts/Prod223_3071_00361854_20210331_modified.html
account_attributes: ['uk-bus:StartDateForPeriodCoveredByReport','bus:NameEntityOfficer','core:AverageNumberEmployeesDuringPeriod','core:NetCurrentAssetsLiabilities','bus:UKCompaniesHouseRegisteredNumber', 'ns5:ParValueShare']