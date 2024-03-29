---
Instances:
  KeepJobFlowAliveWhenNoSteps: ${keep_cluster_alive}
  AdditionalMasterSecurityGroups:
  - "${add_master_sg}"
  AdditionalSlaveSecurityGroups:
  - "${add_slave_sg}"
  Ec2SubnetId: "${subnet_id}"
  EmrManagedMasterSecurityGroup: "${master_sg}"
  EmrManagedSlaveSecurityGroup: "${slave_sg}"
  ServiceAccessSecurityGroup: "${service_access_sg}"
  InstanceFleets:
  - InstanceFleetType: "MASTER"
    Name: MASTER
    TargetOnDemandCapacity: 1
    InstanceTypeConfigs:
    - EbsConfiguration:
        EbsBlockDeviceConfigs:
        - VolumeSpecification:
            SizeInGB: 100
            VolumeType: "gp3"
          VolumesPerInstance: 1
      InstanceType: "${instance_type_master}"
  - InstanceFleetType: "CORE"
    Name: CORE
    TargetOnDemandCapacity: ${core_instance_count}
    InstanceTypeConfigs:
    - EbsConfiguration:
        EbsBlockDeviceConfigs:
        - VolumeSpecification:
            SizeInGB: 100
            VolumeType: "gp3"
          VolumesPerInstance: 1
      InstanceType: "${instance_type_core_one}"
