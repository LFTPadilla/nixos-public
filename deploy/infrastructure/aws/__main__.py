import pulumi
from pulumi_aws import get_caller_identity
import pulumi_aws as aws
from modules import network, security, iam, compute, monitoring
import os

# Configuration
config = pulumi.Config()
stack = pulumi.get_stack()
environment = config.get('environment') or 'production'
# Prefer provider region when explicit project config not set
aws_region = config.get("region") or aws.get_region().name
availability_zone = config.get("availability_zone") or f"{aws_region}a"
ami_ec2 = config.get("ami_ec2")
project_name = config.get('project_name') or 'nixos-cloud'
key_name = config.get('key_name') or 'nixos-cloud-desktop-key'

current = get_caller_identity()
account_id = current.account_id

# Tags for all resources
def create_tags(resource_name: str, additional_tags: dict = None) -> dict:
    base_tags = {
        "Project": project_name,
        "Environment": environment,
        "Stack": stack,
        "ManagedBy": "pulumi",
        "Owner": "nixos-cloud"
    }
    if additional_tags:
        base_tags.update(additional_tags)
    return base_tags

# Protected resource options for critical infrastructure
protected_opts = pulumi.ResourceOptions(
    protect=True,
    retain_on_delete=True
)

# ============================================================================
# NETWORK INFRASTRUCTURE
# ============================================================================

# Create VPC
vpc = network.create_vpc(stack, opts=protected_opts)

# Create two public subnets across AZs
public_subnets = network.create_public_subnets(vpc, aws_region, stack)

# Create Internet Gateway and routing
igw = network.setup_internet_gateway(vpc, stack)
public_route_table = network.create_route_table(vpc, igw, stack)

# Associate public subnets with the public route table
for i, subnet in enumerate(public_subnets, start=1):
    network.associate_route_table(subnet, public_route_table, f"nixos-cloud-rta-public-{i}")

# No private subnets in current setup

# ============================================================================
# SECURITY GROUP
# ============================================================================

# Create application security group restricted to your IP (configure via Pulumi config `allowed_cidr`)
allowed_cidr = config.get("allowed_cidr") or "203.0.113.10/32"
app_security_group = security.create_app_security_group(vpc, stack, allowed_cidr)


# ============================================================================
# IAM ROLES AND POLICIES
# ============================================================================

iam_resources = iam.create_ec2_role(stack)
ec2_role = iam_resources["role"]
instance_profile = iam_resources["instance_profile"]

# ============================================================================
# COMPUTE RESOURCES
# ============================================================================

# EC2 Instance configurations based on environment
instance_configs = [
    {
        "name": "nixos-aws",
        "instance_type": "m7i.large",
        "role": "manager",
        "volume_size": 50,
        "volume_type": "gp3",
        "is_master": True,
        "ami": ami_ec2
    }
]


# Select instance configuration based on environment
# instance_configs = instance_configs_production if environment == "production" else instance_configs_staging

# Create EC2 instances
ec2_resources = compute.create_ec2_instances(
    instance_configs,
    public_subnets[0],
    app_security_group.id,
    instance_profile.name,
    key_name,
    stack
)

instances = ec2_resources["instances"]
eips = ec2_resources["eips"]

# ============================================================================
# APPLICATION LOAD BALANCER
# ============================================================================

# Create Network Load Balancer (better for Traefik SSL passthrough)
# nlb = loadbalancer.create_network_load_balancer(
#     subnet_id=public_subnet.id,  # NLB uses single subnet
#     stack_name=stack
# )

# # Create NLB target groups for HTTP and HTTPS
# http_target_group = loadbalancer.create_target_group(
#     vpc_id=vpc.id,
#     port=80,
#     protocol="TCP",
#     health_check_port=80,
#     stack_name=stack,
#     suffix="http"
# )

# https_target_group = loadbalancer.create_target_group(
#     vpc_id=vpc.id,
#     port=443,
#     protocol="TCP",
#     health_check_port=443,
#     stack_name=stack,
#     suffix="https"
# )

# # Attach EC2 instances to target groups with unique names
# http_attachments = loadbalancer.attach_targets_to_target_group(
#     target_group_arn=http_target_group.arn,
#     instance_ids=[instance.id for instance in instances],
#     port=80,
#     target_suffix="http"
# )

# https_attachments = loadbalancer.attach_targets_to_target_group(
#     target_group_arn=https_target_group.arn,
#     instance_ids=[instance.id for instance in instances],
#     port=443,
#     target_suffix="https"
# )

# # Create NLB listeners (no certificate ARN needed - SSL passthrough)
# http_listener = loadbalancer.create_listener(
#     load_balancer_arn=nlb.arn,
#     port=80,
#     protocol="TCP",
#     target_group_arn=http_target_group.arn,
#     name_suffix="http"
# )

# https_listener = loadbalancer.create_listener(
#     load_balancer_arn=nlb.arn,
#     port=443,
#     protocol="TCP",
#     target_group_arn=https_target_group.arn,
#     name_suffix="https"
# )

# ============================================================================
# MONITORING
# ============================================================================

# Create instance alarms
# instance_alarms = monitoring.create_instance_alarms(instances, stack)

# ============================================================================
# OUTPUTS
# ============================================================================

pulumi.export("vpc_id", vpc.id)
pulumi.export("vpc_cidr", vpc.cidr_block)
pulumi.export("public_subnet_ids", [s.id for s in public_subnets])

# # NLB outputs
# pulumi.export("nlb_arn", nlb.arn)
# pulumi.export("nlb_dns_name", nlb.dns_name)
# pulumi.export("nlb_zone_id", nlb.zone_id)
# pulumi.export("http_target_group_arn", http_target_group.arn)
# pulumi.export("https_target_group_arn", https_target_group.arn)

# EC2 outputs (for debugging and SSH access)
pulumi.export("public_ips", [eip.public_ip for eip in eips])
pulumi.export("private_ips", [instance.private_ip for instance in instances])
pulumi.export("public_dns", [eip.public_dns for eip in eips])
pulumi.export("ssh_command", pulumi.Output.concat("ssh -i ~/.ssh/", key_name, ".pem root@", eips[0].public_ip))


# Tags output for verification
pulumi.export("resource_tags", create_tags("example"))

# No load balancer URLs currently (reserved for future)
