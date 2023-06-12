---
BootstrapActions:
- Name: "download-scripts"
  ScriptBootstrapAction:
    Path: "s3://${s3_config_bucket}/component/dataworks-aws-ch/download-scripts.sh"
- Name: "start-ssm"
  ScriptBootstrapAction:
    Path: "file:/var/ci/start-ssm.sh"
- Name: "metadata"
  ScriptBootstrapAction:
    Path: "file:/var/ci/metadata.sh"
- Name: "config_hcs"
  ScriptBootstrapAction:
    Path: "file:/var/ci/config_hcs.sh"
    Args: [
      "${environment}", 
      "${proxy_http_host}",
      "${proxy_http_port}",
      "${tanium_server_1}",
      "${tanium_server_2}",
      "${tanium_env}",
      "${tanium_port}",
      "${tanium_log_level}",
      "${install_tenable}",
      "${install_trend}",
      "${install_tanium}",
      "${tenantid}",
      "${token}",
      "${policyid}",
      "${tenant}"
    ]
- Name: "emr-setup"
  ScriptBootstrapAction:
    Path: "file:/var/ci/emr-setup.sh"
- Name: "installer"
  ScriptBootstrapAction:
    Path: "file:/var/ci/installer.sh"
- Name: "steps-setup"
  ScriptBootstrapAction:
    Path: "file:/var/ci/steps-setup.sh"
Steps:
- Name: "etl"
  HadoopJarStep:
    Args:
    - "spark-submit"
    - "--master"
    - "yarn"
    - "--conf"
    - "spark.yarn.submit.waitAppCompletion=true"
    - "/opt/emr/steps/etl.py"
    Jar: "command-runner.jar"
  ActionOnFailure: "${action_on_failure}"
