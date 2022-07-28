---
BootstrapActions:
- Name: "start_ssm"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/dataworks-aws-ch/start_ssm.sh"
- Name: "emr-setup"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/dataworks-aws-ch/emr-setup.sh"
- Name: "installer"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/dataworks-aws-ch/installer.sh"
- Name: "download_steps_code"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/dataworks-aws-ch/download_steps_code.sh"
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
