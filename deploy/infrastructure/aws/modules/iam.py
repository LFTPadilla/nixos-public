import pulumi
from pulumi_aws import iam
import json

def create_rds_monitoring_role(stack_name):
    """Create an IAM role for RDS Enhanced Monitoring"""
    # Create the assume role policy for RDS monitoring
    assume_role_policy = json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "monitoring.rds.amazonaws.com"
            }
        }]
    })

    # Create the IAM role
    role = iam.Role(
        'rds-monitoring-role',
        assume_role_policy=assume_role_policy,
        managed_policy_arns=["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"],
        tags={'Name': f'rds-monitoring-role-{stack_name}'}
    )

    return role

def create_ec2_role(stack_name):
    """Create an IAM role for EC2 instances with appropriate permissions"""
    # Create the assume role policy for EC2
    assume_role_policy = json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            }
        }]
    })

    # Create the IAM role
    role = iam.Role(
        'nixos-cloud-ec2-role',
        assume_role_policy=assume_role_policy,
        managed_policy_arns=[
            # Required for Session Manager and SSM Agent
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        ],
        tags={'Name': f'nixos-cloud-ec2-role-{stack_name}'}
    )

    # Attach monitoring policy
    monitoring_policy = iam.RolePolicy(
        'monitoring-policy',
        role=role.id,
        policy=json.dumps({
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "cloudwatch:PutMetricData",
                        "cloudwatch:GetMetricData",
                        "cloudwatch:ListMetrics",
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents",
                        "logs:DescribeLogStreams",
                        "xray:PutTraceSegments",
                        "xray:PutTelemetryRecords",
                        "ssm:GetParameter*",
                        "ssm:DescribeParameters",
                        "elasticfilesystem:DescribeMountTargets"
                    ],
                    "Resource": "*"
                }
            ]
        })
    )

    # Create the instance profile
    instance_profile = iam.InstanceProfile(
        'nixos-cloud-instance-profile',
        role=role.name
    )

    return {
        "role": role,
        "policy": monitoring_policy,
        "instance_profile": instance_profile
    }
