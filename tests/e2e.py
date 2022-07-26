import argparse
from datetime import datetime
import os
import logging
import sys
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


logger = setup_logging("/var/log/dataworks-aws-ch/e2e-tests.log")


def runtime_args():
    try:
        parser = argparse.ArgumentParser(description="Receives expected row and column number")
        parser.add_argument("--rows", type=int, required=True, default=False)
        parser.add_argument("--cols", type=int, required=True, default=False)
        parser.add_argument("--db", type=str, required=True, default=False)
        parser.add_argument("--table", type=str, required=True, default=False)
        parser.add_argument("--partitioning_column", type=str, required=True, default=False)
        args, unrecognized_args = parser.parse_known_args()
        if unrecognized_args:
            logger.warning(f"unrecognised args {unrecognized_args}")
        return args
    except Exception as ex:
        logger.error(f"unable to parse args due to :{ex}")
        sys.exit(-1)


def run_hive_command(cmd):
    logger.info(f"running hive command:{cmd}")
    try:
        cmd = ["hive", "-S", "-e", f"\"{cmd}\""]
        a = subprocess.Popen(cmd, stdout=subprocess.PIPE)
        return a.communicate()[0].decode("utf-8")
    except Exception as ex:
        logger.error(ex)


def rowcount(db: str, table: str, partitioning_column: str):
    logger.info("checking number of rows")
    try:
        date_sent = datetime.strftime(datetime.today().date(), format="%Y-%m-%d")
        cmd = f"SELECT count(*) FROM {db}.{table} where {partitioning_column}='{date_sent}';"
        r = run_hive_command(cmd)
        return int(r)
    except Exception as ex:
        logger.error(ex)


def colcount(db: str, table: str):
    logger.info("checking number of columns")
    try:
        cmd = f"SHOW COLUMNS IN {db}.{table};"
        r = run_hive_command(cmd)
        r = r.replace('\n', ' ')
        r = r.split(' ')
        return len([e for e in r if e != ''])
    except Exception as ex:
        logger.error(ex)


if __name__ == "__main__":

    args = runtime_args()
    actual_cols = colcount(args.db, args.table)
    actual_rows = rowcount(args.db, args.table, args.partitioning_column)
    assert actual_cols == args.cols, logger.error(f"actual cols: {actual_cols} not equal to expected cols: {args.cols}")
    assert actual_rows == args.rows, logger.error(f"actual rows: {actual_rows} not equal to expected rows: {args.rows}")
    logger.info("e2e test for row and col counts passed")
