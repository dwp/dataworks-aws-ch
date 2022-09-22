from deepdiff import DeepDiff
import os
from configparser import ConfigParser
from moto import mock_dynamodb2
from steps.etl import *
import ast
from pyspark.sql import SparkSession
import pytest
import boto3
from moto import mock_s3

test_config_path = "tests/unit_test_conf.tpl"

keys = ["BasicCompanyData-2018-01-01.csv", "BasicCompanyData-2019-01-02.csv",
        "BasicCompanyData-2019-01-03.csv", "BasicCompanyData-2019-01-04.csv", "notacsv.txt"]

keys_only_csv = keys[:-1]


def config(config_file_path: str):
    conf = ConfigParser()
    conf.read(config_file_path)
    return conf


args = config(test_config_path)


@pytest.yield_fixture(scope="session")
def spark_fixture():
    os.environ["PYSPARK_PYTHON"] = "python3"
    os.environ["PYSPARK_DRIVER_PYTHON"] = "python3"
    spark = (
        SparkSession.builder.master("local")
            .appName("ch-test")
            .config("spark.sql.sources.partitionOverwriteMode", "dynamic")
            .enableHiveSupport()
            .getOrCreate()
    )
    yield spark


@pytest.yield_fixture(scope="function")
def s3_fixture():
    mock_s3().start()
    client = boto3.client("s3")
    client.create_bucket(Bucket=args['args']['source_bucket'],
                         CreateBucketConfiguration={"LocationConstraint": args['args']['region']})
    for i in keys:
        client.put_object(
            Bucket=args['args']['source_bucket'], Body=b"some content", Key=os.path.join(args['args']['source_prefix'],i)
        )
    yield client
    mock_s3().stop()


@pytest.yield_fixture(scope="function")
def dynamo_fixture():
    mock_dynamodb2().start()
    dynamodb = boto3.resource("dynamodb", region_name="eu-west-2")
    dynamodb.create_table(
        KeySchema=[
            {"AttributeName": args['audit-table']['hash_key'], "KeyType": "HASH"},
            {"AttributeName": args['audit-table']['range_key'], "KeyType": "RANGE"},
        ],
        AttributeDefinitions=[
            {"AttributeName": args['audit-table']['hash_key'], "AttributeType": "S"},
            {"AttributeName": args['audit-table']['range_key'], "AttributeType": "S"},
        ],
        TableName=args['audit-table']['name'],
    )
    table = dynamodb.Table(args['audit-table']['name'])
    files = ["2018-01-01", "2019-01-01"]
    for f in files:
        table.put_item(
            Item={
                args['audit-table']['hash_key']: args['audit-table']['hash_id'],
                args['audit-table']['range_key']: args['audit-table']['data_product_name'],
                "Latest_File": f,
                "CumulativeSizeBytes": "1234"}
        )
    yield table
    mock_dynamodb2().start()


def test_all_keys(s3_fixture):
    expected = [os.path.join(args['args']['source_prefix'], j) for j in keys]
    s3_client = s3_fixture
    diff = DeepDiff(s3_keys(s3_client, args['args']['source_bucket'], args['args']['source_prefix']),
                    expected, ignore_string_case=False)
    assert diff == {}, "objects uploaded and objects returned differ"


def test_filter_csv_files():
    diff = DeepDiff(filter_csv_files(keys, args['args']['filename']), keys_only_csv,
                    ignore_string_case=False)
    assert diff == {}, "csv files are have not all been identified or other file types are present"


def test_date_regex_extract():
    assert date_regex_extract("e2e-ch/companies/BasicCompanyData-2020-11-11.csv", args['args']['filename']) == "2020-11-11", "filename unique part was not extracted"


def test_get_latest_file(dynamo_fixture):
    assert get_latest_file(dynamo_fixture, args['audit-table']['hash_key'], args['audit-table']['hash_id']) == "2019-01-01"


def test_get_new_key():
    keys = [os.path.join(args['args']['source_prefix'], j) for j in ["BasicCompanyData-2019-01-01.csv", "BasicCompanyData-2019-01-02.csv", "BasicCompanyData-2019-01-03.csv"]]
    latest_file = os.path.join(args['args']['source_prefix'], "BasicCompanyData-2019-01-02.csv")
    expected_key = os.path.join(args['args']['source_prefix'], "BasicCompanyData-2019-01-03.csv")
    diff = DeepDiff(get_new_key(keys, latest_file), expected_key, ignore_string_case=False)
    assert diff == {}, "keys after latest imported files were not filtered"


def test_date_regex_extract():
    assert date_regex_extract("tests/files/BasicCompanyData-2019-01-01.csv") == "2019-01-01", "date was not extracted correctly"


def test_extract_csv(spark_fixture):
    spark = spark_fixture
    df = extract_csv(["tests/files/BasicCompanyData-2019-01-01.csv", "tests/files/BasicCompanyData-2019-01-02.csv"], ast.literal_eval(args['args']['cols']), spark)
    assert df.count() == 6, "read rows are too few or too many"


def test_rename_cols(spark_fixture):
    spark = spark_fixture
    k = ["tests/files/BasicCompanyData-2019-01-01.csv", "tests/files/BasicCompanyData-2019-01-02.csv"]
    df = extract_csv(k, args['args']['cols'], spark)
    dfn = rename_cols(df)
    print(dfn.columns)
    assert all(["." not in col for col in dfn.columns]), ". were not removed"
    assert all([" " not in col for col in dfn.columns]), "spaces were not removed"


def test_create_spark_df(spark_fixture):
    spark = spark_fixture
    key = "tests/files/BasicCompanyData-2019-01-01.csv"
    df = create_spark_df(spark, key, ast.literal_eval(args['args']['cols']), args['args']['partitioning_column'])
    assert df.count() == 3, "total rows are not equal to rows in sample files"
    assert len(df.columns) == len(ast.literal_eval(args['args']['cols']))+1, "united df columns are either more or fewer than expected"


def test_total_size(s3_fixture):
    destination_bucket = args['args']['source_bucket']
    destination_prefix = args['args']['source_prefix']
    s3_client = s3_fixture
    ts = total_size(s3_client, destination_bucket, destination_prefix)
    assert ts == 60, "5 files on the bucket are 12 bytes each but the total size was not 60"


@mock_s3
def test_tag_object():
    bucket = 'test_b'
    prefix = 'test/prefix'
    date = '2019-01-01'
    dates_dont_include = ['2018-01-01', '2019-03-01']
    db = 'test_db'
    tbl = 'test_tbl'
    keys = [os.path.join(prefix, f"{args['args']['partitioning_column']}="+i, "afile.csv") for i in [date]+dates_dont_include]
    keys_expected = [os.path.join(prefix, f"{args['args']['partitioning_column']}="+date, "afile.csv")]
    s3_client = boto3.client("s3")
    s3_client.create_bucket(Bucket=bucket,
                            CreateBucketConfiguration={"LocationConstraint": 'eu-west-2'})
    for i in keys:
        s3_client.put_object(
            Bucket=bucket, Body=b"some content", Key=i
        )
    tag_object(s3_client, bucket, prefix, date, db, tbl, args['args']['partitioning_column'])
    for k in keys:
        response = s3_client.get_object_tagging(
            Bucket=bucket,
            Key=k
        )
        if k in keys_expected:
            assert response['TagSet'][2]['Value'] == tbl
        else:
            assert response['TagSet'] == []
