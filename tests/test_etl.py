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

test_config_path = "tests/test_conf.tpl"

keys = ["BasicCompanyData-2018-01-01-part1_6.csv", "BasicCompanyData-2019-01-01-part1_6.csv",
        "BasicCompanyData-2019-01-02-part1_6.csv", "BasicCompanyData-2019-01-02-part1_7.csv", "notacsv.txt"]

keys_only_csv = ["BasicCompanyData-2018-01-01-part1_6.csv", "BasicCompanyData-2019-01-01-part1_6.csv",
                 "BasicCompanyData-2019-01-02-part1_6.csv", "BasicCompanyData-2019-01-02-part1_7.csv"]


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
    spark.sql("create database if not exists test_db")
    yield spark


@pytest.yield_fixture(scope="function")
def s3_fixture():
    mock_s3().start()
    client = boto3.client("s3")
    client.create_bucket(Bucket=args['args']['publish_bucket'],
                         CreateBucketConfiguration={"LocationConstraint": args['args']['region']})
    for i in keys:
        client.put_object(
            Bucket=args['args']['publish_bucket'], Body=b"some content", Key=args['args']['s3_prefix']+i
        )
    yield client
    mock_s3().stop()


@pytest.yield_fixture(scope="function")
def dynamo_fixture():
    mock_dynamodb2().start()
    dynamodb = boto3.resource("dynamodb",region_name="eu-west-2")
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
    files = ["2018-01-01-part2_6", "2019-01-01-part2_6"]
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
    expected = [os.path.join(args['args']['s3_prefix'], j) for j in keys]
    s3_client = s3_fixture
    diff = DeepDiff(s3_keys(s3_client, args['args']['publish_bucket'], args['args']['s3_prefix']),
                    expected, ignore_string_case=False)
    assert diff == {}, "objects uploaded and objects returned differ"


def test_csv_files_only():
    diff = DeepDiff(csv_files_only(keys, args['args']['filename']), keys_only_csv,
                    ignore_string_case=False)
    assert diff == {}, "csv files are have not all been identified or other file types are present"


def test_file_regex_extract():
    assert file_regex_extract("e2e-ch/companies/BasicCompanyData-2020-11-11-part1_6.csv", args['args']['filename']) == "2020-11-11-part1_6", "filename unique part was not extracted"


def test_file_latest_dynamo_fetch(dynamo_fixture):
    assert file_latest_dynamo_fetch(dynamo_fixture, args['audit-table']['hash_key'], args['audit-table']['hash_id']) == "2019-01-01-part2_6"


def test_filter_keys():
    k = ["BasicCompanyData-2019-01-01-part2_6.csv", "BasicCompanyData-2019-01-01-part1_6.csv",
         "BasicCompanyData-2019-01-02-part1_6.csv", "BasicCompanyData-2019-01-02-part1_7.csv"]

    inp = [os.path.join(args['args']['s3_prefix'], j) for j in k]
    expected = inp[-2:]


    diff = DeepDiff(filter_keys(inp[0], inp, args['args']['filename']), (expected, expected[-1]),
                    ignore_string_case=False)
    assert diff == {}, "keys after latest imported files were not filtered"


def test_date_regex_extract():
    assert date_regex_extract("tests/files/BasicCompanyData-2019-01-01-part1_6.csv", args['args']['filename']) == "2019-01-01", "date was not extracted correctly"


def test_keys_by_date():
    k = ["BasicCompanyData-2019-01-02-part1_6.csv", "BasicCompanyData-2019-01-01-part1_7.csv", "BasicCompanyData-2019-01-02-part1_6.csv"]
    inp = [os.path.join(args['args']['s3_prefix'], j) for j in k]

    expected = {"2019-01-02": [os.path.join("s3://"+args['args']['publish_bucket'], inp[0]),
                               os.path.join("s3://"+args['args']['publish_bucket'], inp[2])],
                "2019-01-01": [os.path.join("s3://"+args['args']['publish_bucket'], inp[1])]}
    diff = DeepDiff(keys_by_date(inp, args['args']['filename'], args['args']['publish_bucket']), expected, ignore_string_case=False)
    assert diff == {}, "keys were not correctly split into list by date"


def test_extract_csv(spark_fixture):
    spark = spark_fixture
    df = extract_csv(["tests/files/BasicCompanyData-2019-01-01-part1_6.csv", "tests/files/BasicCompanyData-2019-01-01-part2_6.csv"], ast.literal_eval(args['args']['cols']), spark)
    assert df.count() == 6, "read rows are too few or too many"


def test_rename_cols(spark_fixture):
    spark = spark_fixture
    k = ["tests/files/BasicCompanyData-2019-01-01-part1_6.csv", "tests/files/BasicCompanyData-2019-01-01-part2_6.csv"]
    df = extract_csv(k, args['args']['cols'], spark)
    dfn = rename_cols(df)
    print(dfn.columns)
    assert all(["." not in col for col in dfn.columns]), ". were not removed"
    assert all([" " not in col for col in dfn.columns]), "spaces were not removed"


def test_create_spark_dfs(spark_fixture):
    spark = spark_fixture
    kbd = {"2019-01-01": ["tests/files/BasicCompanyData-2019-01-01-part1_6.csv", "tests/files/BasicCompanyData-2019-01-01-part2_6.csv"]}
    df = create_spark_dfs(spark, kbd, ast.literal_eval(args['args']['cols']), args['args']['partitioning_column'])
    assert df.count() == 6, "total rows are not equal to sum of rows in the two sample files"
    assert len(df.columns) == len(ast.literal_eval(args['args']['cols']))+1, "united df columns are more or less than expected"


def test_parquet_writer(spark_fixture):
    spark = spark_fixture
    kbd = {"2019-01-01": ["tests/files/BasicCompanyData-2019-01-01-part1_6.csv", "tests/files/BasicCompanyData-2019-01-01-part2_6.csv"]}
    df = create_spark_dfs(spark, kbd, ast.literal_eval(args['args']['cols']), args['args']['partitioning_column'])
    writer_parquet(df, args['args']['destination_prefix'], args['args']['partitioning_column'])
    assert os.listdir(f"{args['args']['destination_prefix']}") == [f"{args['args']['partitioning_column']}=2019-01-01"], "parquet partitions not all created"


def test_total_size(s3_fixture):
    s3_client = s3_fixture
    ts = total_size(s3_client, args['args']['publish_bucket'], args['args']['s3_prefix'])
    assert ts == 60, "5 files on the bucket are 12 bytes each but the total size was not 60"


@mock_s3
def test_tag_objects():
    bucket = 'test_b'
    prefix = 'test/prefix'
    dates = ['2019-01-01', '2019-01-01']
    dates_dont_include = ['2018-01-01', '2019-03-01']
    db = 'test_db'
    tbl = 'test_tbl'
    keys = [os.path.join(prefix, "date_uploaded="+i, "afile.csv") for i in dates+dates_dont_include]
    keys_expected = [os.path.join(prefix, "date_uploaded="+i, "afile.csv") for i in dates]
    s3_client = boto3.client("s3")
    s3_client.create_bucket(Bucket=bucket,
                            CreateBucketConfiguration={"LocationConstraint": 'eu-west-2'})
    for i in keys:
        s3_client.put_object(
            Bucket=bucket, Body=b"some content", Key=i
        )
    tag_objects(s3_client, bucket, prefix, dates, db, tbl)

    for k in keys:
        response = s3_client.get_object_tagging(
            Bucket=bucket,
            Key=k
        )

        if k in keys_expected:
            assert response['TagSet'][2]['Value'] == tbl
        else:
            assert response['TagSet'] == []
