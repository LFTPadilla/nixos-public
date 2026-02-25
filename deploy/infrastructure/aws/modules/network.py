import pulumi
from pulumi_aws import ec2

def create_vpc(stack_name, cidr_block="10.0.0.0/16", opts=None):
    """Create a VPC with DNS support"""
    vpc = ec2.Vpc(
        'nixos-cloud-vpc',
        cidr_block=cidr_block,
        enable_dns_hostnames=True,
        enable_dns_support=True,
        tags={'Name': f'nixos-cloud-vpc-{stack_name}'},
        opts=opts
    )
    return vpc

def create_public_subnets(vpc, aws_region, stack_name,
                          cidr_blocks=("10.0.1.0/24", "10.0.2.0/24")):
    """Create two public subnets across AZs (a, b)."""
    azs = (f"{aws_region}a", f"{aws_region}b")
    subnets = []
    for idx, (cidr, az) in enumerate(zip(cidr_blocks, azs), start=1):
        subnet = ec2.Subnet(
            f'nixos-cloud-public-subnet-{idx}',
            vpc_id=vpc.id,
            cidr_block=cidr,
            map_public_ip_on_launch=True,
            availability_zone=az,
            tags={'Name': f'nixos-cloud-public-subnet-{stack_name}-{idx}'},
        )
        subnets.append(subnet)
    return subnets


def create_public_subnet(vpc, availability_zone, stack_name, cidr_block="10.0.1.0/24"):
    """Create a public subnet in the VPC"""
    subnet = ec2.Subnet(
        'nixos-cloud-public-subnet',
        vpc_id=vpc.id,
        cidr_block=cidr_block,
        map_public_ip_on_launch=True,
        availability_zone=availability_zone,
        tags={'Name': f'nixos-cloud-public-subnet-{stack_name}'},
        # opts=pulumi.ResourceOptions(protect=True)
    )
    return subnet

def setup_internet_gateway(vpc, stack_name):
    """Create and attach an internet gateway"""
    igw = ec2.InternetGateway(
        'nixos-cloud-igw',
        vpc_id=vpc.id,
        tags={'Name': f'nixos-cloud-igw-{stack_name}'},
        # opts=pulumi.ResourceOptions(protect=True)
    )
    return igw

def create_route_table(vpc, igw, stack_name):
    """Create a route table with a route to the internet gateway"""
    route_table = ec2.RouteTable(
        'nixos-cloud-rt',
        vpc_id=vpc.id,
        routes=[
            ec2.RouteTableRouteArgs(
                cidr_block='0.0.0.0/0',
                gateway_id=igw.id
            )
        ],
        tags={'Name': f'nixos-cloud-rt-{stack_name}'},
        # opts=pulumi.ResourceOptions(protect=True)
    )
    return route_table


def associate_route_table(subnet, route_table, association_name=None):
    """Associate a subnet with a route table"""
    if association_name is None:
        association_name = f'nixos-cloud-rta-{subnet._name}' if hasattr(subnet, '_name') else 'nixos-cloud-rta'

    rta = ec2.RouteTableAssociation(
        association_name,
        subnet_id=subnet.id,
        route_table_id=route_table.id,
        # opts=pulumi.ResourceOptions(protect=True)
    )
    return rta
