(
# Import the logging functions
source /opt/emr/logging.sh


function log_wrapper_message() {
  log_ch_message "$${1}" "download_steps_code.sh" "$${PID}" "$${@:2}" "Running as: ,$USER"
}

URL="s3://${s3_bucket_id}/${s3_bucket_prefix}"

log_wrapper_message "Downloading latest codes"

$(which aws) s3 cp "$URL/steps/" "/opt/emr" --recursive

)  >> /var/log/dataworks-aws-ch/download_steps_code.log 2>&1
