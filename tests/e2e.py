import argparse
import datetime
from datetime import timedelta
import os
import logging
import sys
import boto3
import subprocess


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


def runtime_args():

    try:
        parser = argparse.ArgumentParser(description="Receives expected row and column number")
        parser.add_argument("--rows", type=int, required=True, default=False)
        parser.add_argument("--cols", type=int, required=True, default=False)
        parser.add_argument("--db", type=str, required=True, default=False)
        parser.add_argument("--table", type=str, required=True, default=False)
        args, unrecognized_args = parser.parse_known_args()
        if unrecognized_args:
            logger.warning(f"unrecognised args {unrecognized_args}")
        return args
    except Exception as ex:
        logger.error(f"unable to parse args due to :{ex}")
        sys.exit(-1)

def run_hive_command(cmd):

    cmd = ["hive", "-S", "-e", f"\"{cmd}\""]
    a = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    return a.communicate()[0].decode("utf-8")


def rowcount(db: str, table: str, partitioning_column):

    cmd = f"SELECT count(*) FROM {db}.{table} WHERE {partitioning_column} BETWEEN '{str(datetime.date.today()-timedelta(1))}' AND '{str(datetime.date.today())}';"
    r = run_hive_command(cmd)
    return int(r)


def colcount(db: str, table: str):

    cmd = f"SHOW COLUMNS IN {db}.{table};"
    r = run_hive_command(cmd)
    r = r.replace('\n', ' ')
    r = r.split(' ')
    return len([e for e in r if e != ''])


if __name__ == "__main__":

    args = runtime_args()
    actual_cols = colcount(args.db, args.table)
    actual_rows = rowcount(args.db, args.table, 'UploadedOnSource')
    logger.info("checking number of columns")
    assert actual_cols == args.cols, f"actual cols: {actual_cols} not equal to expected cols: {args.cols}"
    logger.info("checking number of rows")
    assert actual_rows == args.rows, f"actual rows: {actual_rows} not equal to expected rows: {args.rows}"
    logger.info("test for row and col counts passed")