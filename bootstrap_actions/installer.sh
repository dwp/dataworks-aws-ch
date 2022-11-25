#!/bin/bash

(
    # Import the logging functions
    source /opt/emr/logging.sh

    function log_wrapper_message() {
        log_ch_message "$${1}" "installer.sh" "$${PID}" "$${@:2}" "Running as: ,$USER"
    }

    log_wrapper_message "Installing boto3 packages"
    PIP=/usr/bin/pip3

    if [ ! -x $PIP ]; then
    # EMR <= 5.29.0 doesn't install a /usr/bin/pip3 wrapper
    PIP=/usr/bin/pip-3.6
    fi

    # No sudo needed to write to file for any of the below, so redirect is fine
    #shellcheck disable=SC2024
    sudo -E $PIP install boto3==1.23.1 >> /var/log/dataworks-aws-ch/install-boto3.log 2>&1
    #shellcheck disable=SC2024
    sudo -E $PIP install requests >> /var/log/dataworks-aws-ch/install-requests.log 2>&1

    #shellcheck disable=SC2024
    {
        sudo yum install -y python3-devel
        sudo -E $PIP install pycrypto
        sudo -E $PIP install pycryptodome
        sudo yum remove -y python3-devel
    } >> /var/log/dataworks-aws-ch/install-pycrypto.log 2>&1

    log_wrapper_message "Completed the installer.sh step of the EMR Cluster"

) >> /var/log/dataworks-aws-ch/installer.log 2>&1
