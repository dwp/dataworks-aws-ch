#!/bin/bash
set -euo pipefail
(
    # Import the logging functions
    source /opt/emr/logging.sh

    function log_wrapper_message() {
        log_ch_message "$1" "steps-setup.sh" "$$" "Running as: $USER"
    }

    log_wrapper_message "Moving maria db jar to spark jars folder"
    sudo mkdir -p /usr/lib/spark/jars/
    sudo cp /usr/share/java/mariadb-connector-java.jar /usr/lib/spark/jars/

    log_wrapper_message "Setting up EMR steps folder"
    sudo mkdir -p /opt/emr/steps
    sudo chown hadoop:hadoop /opt/emr/steps

    log_wrapper_message "Creating init py file"
    touch /opt/emr/steps/__init__.py

    log_wrapper_message "Moving python steps files to steps folder"
    aws s3 cp "${etl_script}" /opt/emr/steps/etl.py
    aws s3 cp "${etl_e2e}" /opt/emr/steps/e2e.py
    aws s3 cp "${etl_e2e_conf}" /opt/emr/steps/e2e_test_conf.tpl
    aws s3 cp "${etl_conf}" /opt/emr/steps/conf.tpl
    sudo chown -R hadoop:hadoop /opt/emr/steps

    log_wrapper_message "Scripts in steps folder:"
    ls  /opt/emr/steps

) >> /var/log/dataworks-aws-ch/steps-setup.log 2>&1


