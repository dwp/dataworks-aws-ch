import re
from functools import reduce
from boto3.dynamodb.conditions import Key
from configparser import ConfigParser
from pyspark.sql.types import StructField, StringType
import argparse
import ast
import logging
import os
import sys
from pyspark.sql.functions import lit
from pyspark.sql import SparkSession, DataFrame
import boto3


def setup_logging(log_path=None):
    json_format = "{ \"timestamp\": \"%(asctime)s\", \"log_level\": \"%(levelname)s\", \"message\": \"%(message)s\"}"
    log_level = os.environ["LOG_LEVEL"].upper() if "LOG_LEVEL" in os.environ else "INFO"
    the_logger = logging.getLogger()
    for old_handler in the_logger.handlers:
        the_logger.removeHandler(old_handler)
    if log_path is None:
        handler = logging.StreamHandler(sys.stdout)
    else:
        handler = logging.FileHandler(log_path)
        handler.setFormatter(logging.Formatter(json_format))
        the_logger.addHandler(handler)
        new_level = logging.getLevelName(log_level.upper())
        the_logger.setLevel(new_level)
    return the_logger


logger = setup_logging()


def file_latest_dynamo_add(latest_file: str, cum_size: int):
    logger.info("writing new file name of latest import to dynamo table")
    try:
        table.put_item(
            Item={
                args['audit-table']['hash_key']: args['audit-table']['hash_id'],
                args['audit-table']['range_key']: args['audit-table']['data_product_name'],
                "Latest_File": latest_file,
                "CumulativeSizeBytes": cum_size
            }
        )
    except Exception as ex:
        logger.error(f"failed to add item to dynamodb due to {ex}")
        sys.exit(-1)


def file_latest_dynamo_fetch(table, hash_key, hash_id):
    logger.info("getting last imported file name from dynamo")
    try:
        response = table.query(KeyConditionExpression=Key(hash_key).eq(hash_id), ScanIndexForward=False)
        if not response['Items']:
            logger.error("couldn't find any items for set hash key")
            sys.exit(-1)
        else:
            return response["Items"][0]["Latest_File"]
    except Exception as ex:
        logger.error(f"failed to fetch last filename imported due to {ex}")
        sys.exit(-1)


def date_regex_extract(filename: str, filenames_prefix: str):
    logger.info(f"extracting date from file name {filename}")
    try:
        pattern = f".*{filenames_prefix}"+"-([0-9]{4}-[0-9]{2}-[0-9]{2})-part.*\.csv"
        match = re.findall(pattern, filename)
        return match[0]
    except Exception as ex:
        logger.error(f"failed to extract date from file name {filename} due to {ex}")
        sys.exit(-1)


def file_regex_extract(filename: str, filename_prefix: str):
    logger.info(f"extracting suffix from file name {filename}")
    try:
        pattern = f".*{filename_prefix}"+"-([0-9]{4}-[0-9]{2}-[0-9]{2}-part.*)\.csv"
        match = re.findall(pattern, filename)
        return match[0]
    except Exception as ex:
        logger.error(f"failed to extract suffix from file name {filename} due to {ex}")
        sys.exit(-1)


def csv_files_only(keys: list, filenames_prefix: str):
    logger.info("filtering keys")
    filenames_regex = f".*{filenames_prefix}-.*\.csv"
    try:
        matches = [key for key in keys if re.match(filenames_regex, key)]
        if len(matches) == 0:
            logger.warning("no csv files. exiting...")
            sys.exit(0)
        return matches
    except Exception as ex:
        logger.error(f"failed to extract s3 keys with regex due to {ex}")
        sys.exit(-1)


# def read_zipped_csv(s3_location):
#     try:
#         return pd.read_csv(s3_location)
#     except Exception as ex:
#         logger.error(f"failed to read zip file from s3 due to {ex}")
#         sys.exit(-1)


def schema_spark(schema: list):
    logger.info("build spark schema from list of cols")
    try:
        return [StructField(i, StringType(), True) for i in schema]
    except Exception as ex:
        logger.error(f"failed to build spark schema from given columns {schema} due to {ex}")

# def create_spark_df(pandas_df, schema):
#     logger.info("creating a spark df from pandas df")
#     try:
#         return spark.createDataFrame(pandas_df, schema)
#     except Exception as ex:
#         logger.error(f"failed to create a spark df from pandas df with schema {schema} due to {ex}")


def filter_keys(filename, keys, filename_prefix):
    logger.info(f"filtering files added after latest imported file")
    try:
        new_keys = []
        keys_filename = [file_regex_extract(key, filename_prefix) for key in keys]
        if filename not in keys_filename:
            keys_filename.append(filename)
        logger.warning(f"keys including file latest {keys_filename}")
        keys_filename.sort(reverse=False)
        keys_sort = keys_filename
        logger.warning(f"keys sorted {keys_sort}")
        l = len(keys_sort)
        idx = keys_sort.index(filename)+1
        if idx == l:
            logger.warning(f"no new files after {filename}")
            exit(0)
        for i in keys_sort[idx:]:
            for j in keys:
                if i in j:
                    new_keys.append(j)
        if len(new_keys) == 0:
            logger.warning("no new files since last import. exiting...")
            sys.exit(0)
        logger.info(f"{len(new_keys)} new files were added after last import")
        return new_keys, file_regex_extract(new_keys[-1], filename_prefix)
    except Exception as ex:
        logger.error(f"failed to filter keys added after latest imported file due to {ex}")


def union_all(df_list):
    logger.info("unioning list of dfs")
    try:
        return reduce(DataFrame.union, df_list)
    except Exception as ex:
        logger.error(f"failed to union all dfs due to {ex}")
        sys.exit(-1)


def tag_objects(s3_client, bucket, prefix: str, dates: list, db, tbl, col):
    try:
        for date in dates:
            dt_path = os.path.join(prefix, f"{col}={date}/")
            logger.info(f"S3 Prefix {dt_path}")
            for key in s3_client.list_objects(Bucket=bucket, Prefix=dt_path)["Contents"]:
                filename = key["Key"]
                response = s3_client.put_object_tagging(
                    Bucket=bucket,
                    Key=key["Key"],
                    Tagging={"TagSet": [{"Key": "pii", "Value": "false"},
                                        {"Key": "db", "Value": db},
                                        {"Key": "table", "Value": tbl}]},
                )
                status = response['ResponseMetadata']['HTTPStatusCode']
                logger.info(f"Tagging: s3 client response status: {status}, table: {tbl}, filename: {filename}")
    except Exception as ex:
        logger.error(f"Failed to tag s3 objects due to {ex}")
        sys.exit(-1)


def extract_csv(keys: list, schema, spark):
    logger.info("reading csv files into spark dataframe")
    try:
        df = spark.read \
            .option("header", True) \
            .option("schema", schema) \
            .option("multiline", True) \
            .format("csv") \
            .load(keys)
    except Exception as ex:
        logger.error(f"failed to read the csv file into spark dataframe due to {ex}")
        sys.exit(-1)
    return df


def rename_cols(df):
    new_column_name_list = list(map(lambda x: x.replace(" ", "").replace(".", "_"), df.columns))
    dfn = df.toDF(*new_column_name_list)
    return dfn


def keys_by_date(keys: list, filenames_prefix, bucket) -> dict:
    logger.info("creating dict of keys by date")
    try:
        kbd = {}
        dates = [date_regex_extract(filename, filenames_prefix) for filename in keys]
        for date in dates:
            kbd[date] = [os.path.join("s3://"+bucket, filename) for filename in keys if date in filename]
        return kbd
    except Exception as ex:
        logger.error(f"failed creating dict of keys by date due to {ex}")
        sys.exit(-1)


def create_spark_dfs(sp, kbd: dict, schema, partitioning_column):
    try:
        dfs = []
        for k, v in kbd.items():
            df = extract_csv(v, schema, sp)
            df = rename_cols(df)
            df = add_partitioning_column(df, k, partitioning_column)
            dfs.append(df)
        res = union_all(dfs)
    except Exception as ex:
        logger.error(f"failed creating spark df due to {ex}")
        sys.exit(-1)
    return res


def s3_keys(s3_client, bucket_id, prefix: str) -> list:
    logger.info(f"looking for s3 objects with prefix {prefix}")
    try:
        keys = []
        paginator = s3_client.get_paginator("list_objects_v2")
        pages = paginator.paginate(Bucket=bucket_id, Prefix=prefix)
        for page in pages:
            if "Contents" in page:
                keys = keys + [obj["Key"] for obj in page["Contents"]]

        if len(keys) == 0:
            logger.info(f"no keys found under set prefix {prefix}")
            exit(0)
        logger.info(f"found {len(keys)} under set prefix {prefix}")
        logger.info(f"key under set prefix {prefix}: {keys}")

        return keys
    except Exception as ex:
        logger.error(f"failed to list keys in bucket due to {ex}")
        sys.exit(-1)


def total_size(s3_client, bucket, prefix):
    logger.info(f"looking for s3 objects with prefix {prefix}")
    try:
        size = 0
        paginator = s3_client.get_paginator("list_objects_v2")
        pages = paginator.paginate(Bucket=bucket, Prefix=prefix)
        for page in pages:
            if "Contents" in page:
                print(page["Contents"])
                for obj in page["Contents"]:
                    size = size + int(obj["Size"])
        return size
    except Exception as ex:
        logger.error(f"failed calculate total import size {ex}")
        sys.exit(-1)


def get_s3_client():
    logger.info("getting s3 client")
    try:
        return boto3.client("s3")
    except Exception as ex:
        logger.error(f"failed to get an s3 client due to {ex}")
        sys.exit(-1)


def spark_session():
    logger.info("building spark session")
    try:
        spark = (
            SparkSession.builder.master("yarn")
                .appName(f'company_etl')
                .enableHiveSupport()
                .getOrCreate()
        )
        spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")
    except Exception as ex:
        logger.error(f"failed to create spark session due to {ex}")
        sys.exit(-1)
    return spark


def writer_parquet(df, s3_destination, partitioning_column):
    logger.info(f"writing parquet files partitioned by {partitioning_column} on {s3_destination}")
    try:
        df.write \
            .mode('Overwrite') \
            .partitionBy(partitioning_column) \
            .parquet(s3_destination)
    except Exception as ex:
        logger.error(f"failed to write the transformed dataframe due to {ex}")


def add_partitioning_column(df, val, partitioning_column):
    logger.info(f"adding new column {partitioning_column} with value {val}")
    try:
        return df.withColumn(partitioning_column, lit(val))
    except Exception as ex:
        logger.error(f"failed to add partitioning column due to {ex}")


def build_hive_schema(df, partitioning_column):
    logger.info(f"building hive schema from spark df")
    try:
        schema = ',\n'.join([f"{item[0]} {item[1]}" for item in df.dtypes if partitioning_column not in item])
        return schema
    except Exception as ex:
        logger.error(f"failed to build hive schema from df due to {ex}")


def dynamo_table(region):
    logger.info("getting dynamodb table")
    try:
        dynamodb = boto3.resource("dynamodb", region_name=region)
    except Exception as ex:
        logger.error(f"failed to get dynamo table due to {ex}")
        sys.exit(-1)
    return dynamodb.Table(args['audit-table']['name'])


def config(config_file_path: str):
    # logger.info(f"getting args from file {config_file_path}")
    try:
        conf = ConfigParser()
        conf.read(config_file_path)
        return conf
    except Exception as ex:
        # logger.error(f"failed to load configuration file {config_file_path} due to {ex}")
        print(ex)
        # sys.exit(-1)


def recreate_hive_table(df, path, db_name, table_name, sp, partitioning_column):
    try:
        create_db_query = f"""CREATE DATABASE IF NOT EXISTS {db_name}"""
        logger.info(f"creating {db_name} database")
        sp.sql(create_db_query)
        hive_schema = build_hive_schema(df, partitioning_column)
        src_hive_table = db_name + "." + table_name
        src_hive_drop_query = f"""DROP TABLE IF EXISTS {src_hive_table}"""
        logger.info(f"dropping table {table_name}")
        sp.sql(src_hive_drop_query)
        src_hive_create_query = f"""
        CREATE EXTERNAL TABLE IF NOT EXISTS {src_hive_table} (
        {hive_schema}
        ) STORED AS PARQUET 
        PARTITIONED BY ({partitioning_column} STRING)
        LOCATION '{path}'
        """
        logger.info(f"creating table {table_name} ")
        sp.sql(src_hive_create_query)
        sp.sql(f"MSCK REPAIR TABLE {src_hive_table}")

    except Exception as ex:
        logger.error(f"failed to recreate hive tables with error {ex}")


def runtime_args():
    try:
        parser = argparse.ArgumentParser(description="Receives args provided to spark submit job")
        parser.add_argument("--e2e", type=bool, required=False, default=False)
        args, unrecognized_args = parser.parse_known_args()
        if unrecognized_args:
            logger.warning(f"Found unknown args during runtime {unrecognized_args}")
        if args.e2e == True:
            logger.info("e2e set on True so appropriate e2e s3 folders will be set")
        return args
    except Exception as ex:
        logger.error(f"Failed to read runtime args due to {ex}")
        sys.exit(-1)


def all_args():
    args = config("/opt/emr/conf.tpl")
    r_args = runtime_args()
    if r_args.e2e:
        args['args']['log_path'] = args['args']['e2e_log_path']
        args['args']['s3_prefix'] = args['args']['e2e_s3_prefix']
    return args


if __name__ == "__main__":
    args = all_args()
    logger = setup_logging(args['args']['log_path'])
    table = dynamo_table(args['args']['region'])
    s3_client = get_s3_client()
    spark = spark_session()
    all_keys = s3_keys(s3_client, args['args']['stage_bucket'], args['args']['s3_prefix'])
    logger.warning(f"all_keys {all_keys}")
    keys = csv_files_only(all_keys, args['args']['filename'])
    logger.warning(f"keys {keys}")
    file_latest = file_latest_dynamo_fetch(table, args['audit-table']['hash_key'], args['audit-table']['hash_id'])
    logger.warning(f"file latest {file_latest}")
    new_keys, new_suffix_latest_import = filter_keys(file_latest, keys, args['args']['filename'])
    kbd = keys_by_date(new_keys, args['args']['filename'], args['args']['stage_bucket'])
    spark_df = create_spark_dfs(spark, kbd, ast.literal_eval(args['args']['cols']), args['args']['partitioning_column'])
    destination = os.path.join("s3://"+args['args']['publish_bucket'], args['args']['destination_prefix'])
    writer_parquet(spark_df, destination, args['args']['partitioning_column'])
    db = args['args']['db_name']
    tbl = args['args']['table_name']
    recreate_hive_table(spark_df, destination, db, tbl, spark, args['args']['partitioning_column'])
    dates = list(kbd.keys())
    tag_objects(s3_client, args['args']['publish_bucket'], args['args']['destination_prefix'], dates, db, tbl, args['args']['partitioning_column'])
    cum_size = total_size(s3_client, args['args']['publish_bucket'], args['args']['destination_prefix'])
    file_latest_dynamo_add(new_suffix_latest_import, cum_size)
