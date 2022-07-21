(
# Import the logging functions
source /opt/emr/logging.sh

function log_wrapper_message() {
  log_ch_message "$${1}" "download_steps_code.sh" "$${PID}" "$${@:2}" "Running as: ,$USER"
}

URL="s3://${s3_bucket_id}/${s3_bucket_prefix}"
Download_DIR=/opt/emr/steps
ZIP_DIR=/opt/emr/steps/utils

echo "Download latest spark codes"
log_wrapper_message "Downloading latest spark codes"

$(which aws) s3 cp "$URL/steps/" $Download_DIR --recursive

echo "SCRIPT_DOWNLOAD_URL: $URL/steps/"

log_wrapper_message "script_download_url: $URL/steps/"

)  >> /var/log/ch/download_steps_code.log 2>&1
