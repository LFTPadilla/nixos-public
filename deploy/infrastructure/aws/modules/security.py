import pulumi
from pulumi_aws import ec2

def create_app_security_group(vpc, stack_name, allowed_cidr: str = "181.53.99.101/32"):
    """Create a security group for the application servers (EC2 instances)
    Only allows inbound SSH from the provided CIDR (HTTP/HTTPS commented for future use).
    """

    # Base ingress rules
    ingress_rules = [
        ec2.SecurityGroupIngressArgs(
            protocol='tcp',
            from_port=22,
            to_port=22,
            cidr_blocks=[allowed_cidr]
        ),
        # To expose web only to your IP, uncomment and keep cidr restricted:
        # ec2.SecurityGroupIngressArgs(
        #     protocol='tcp',
        #     from_port=80,
        #     to_port=80,
        #     cidr_blocks=[allowed_cidr]
        # ),
        # ec2.SecurityGroupIngressArgs(
        #     protocol='tcp',
        #     from_port=443,
        #     to_port=443,
        #     cidr_blocks=[allowed_cidr]
        # ),
    ]

    security_group = ec2.SecurityGroup(
        'nixos-cloud-sg',
        description='Security group for nixos-cloud application servers',
        vpc_id=vpc.id,
        ingress=ingress_rules,
        egress=[
            ec2.SecurityGroupEgressArgs(
                protocol='-1',
                from_port=0,
                to_port=0,
                cidr_blocks=['0.0.0.0/0']
            )
        ],
        tags={'Name': f'nixos-cloud-sg-{stack_name}'}
    )
    return security_group
