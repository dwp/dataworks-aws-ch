---
BootstrapActions:
- Name: "start_ssm"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/ch/start_ssm.sh"
- Name: "metadata"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/kickstart-analytical-dataset-generation/metadata.sh"
- Name: "emr-setup"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/ch/emr-setup.sh"
- Name: "installer"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/ch/installer.sh"
- Name: "download_steps_code"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/ch/download_steps_code.sh"
Steps:
- Name: "submit-job-payment"
  HadoopJarStep:
    Args:
    - "spark-submit"
    - "--master"
    - "yarn"
    - "--conf"
    - "spark.yarn.submit.waitAppCompletion=true"
    - "--py-files"
    - "/opt/emr/steps/jobs.zip"
    - "/opt/emr/steps/etl.py"
    Jar: "command-runner.jar"
  ActionOnFailure: "${action_on_failure}"
