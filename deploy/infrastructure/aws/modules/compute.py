import pulumi
from pulumi_aws import ec2, efs
import json

def create_ec2_instances(config, public_subnet, security_group_id, instance_profile_name, key_name, stack_name):
    """Create EC2 instances based on the provided configuration"""
    instances = []
    eips = []
    eip_assocs = []

    # User data script for EC2 instances
    user_data = """#!/bin/bash
    sudo apt-get update
    """

    for i, config in enumerate(config, start=1):
        eip_name = f'{config["name"]}-eip'
        eip_tag = f'{config["name"]}-eip-{stack_name}'

        # Create Elastic IP
        eip = ec2.Eip(eip_name,
            domain="vpc",
            tags={'Name': eip_tag}
        )
        eips.append(eip)

        # Create EC2 instance
        instance = ec2.Instance(
            config["name"],
            instance_type=config["instance_type"],
            subnet_id=public_subnet.id,
            ami=config.get("ami"),
            vpc_security_group_ids=[security_group_id],
            iam_instance_profile=instance_profile_name,
            user_data=user_data,
            key_name=key_name,
            root_block_device=ec2.InstanceRootBlockDeviceArgs(
                volume_size=config["volume_size"],
                volume_type=config["volume_type"],
            ),
            tags={
                'Name': f'{config["name"]}-{stack_name}',
                "node.role": config["role"],
                "is_master": str(config["is_master"])
            },
        )
        instances.append(instance)

        # Associate Elastic IP with EC2 instance
        eip_assoc = ec2.EipAssociation(f'{config["name"]}-eip-assoc',
            instance_id=instance.id,
            allocation_id=eip.id
        )
        eip_assocs.append(eip_assoc)

    return {
        "instances": instances,
        "eips": eips,
        "eip_assocs": eip_assocs
    }

def create_efs_file_system(stack_name):
    """Create an EFS file system"""
    efs_file_system = efs.FileSystem(
        "nixos-cloud-efs",
        encrypted=True,
        tags={"Name": f"nixos-cloud-efs-{stack_name}"},
        # opts=pulumi.ResourceOptions(protect=True)
    )
    return efs_file_system

def create_efs_mount_target(file_system_id, subnet_id, security_group_ids):
    """Create an EFS mount target in the specified subnet"""
    mount_target = efs.MountTarget(
        "nixos-cloud-efs-mt",
        file_system_id=file_system_id,
        subnet_id=subnet_id,
        security_groups=security_group_ids
    )
    return mount_target
