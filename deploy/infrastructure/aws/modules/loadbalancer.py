import pulumi
from pulumi_aws import lb

def create_network_load_balancer(subnet_id, stack_name):
    """Create a Network Load Balancer"""
    network_lb = lb.LoadBalancer(
        'nixos-cloud-nlb',
        internal=False,
        load_balancer_type='network',
        subnets=[subnet_id],
        enable_deletion_protection=False,
        tags={'Name': f'nixos-cloud-nlb-{stack_name}'},
        # opts=pulumi.ResourceOptions(protect=True)
    )
    return network_lb

def create_target_group(vpc_id, port, protocol, health_check_port, stack_name, suffix=""):
    """Create a target group for the load balancer"""
    name_suffix = f"-{suffix}" if suffix else ""

    target_group = lb.TargetGroup(
        f'nixos-cloud-target-group{name_suffix}',
        port=port,
        protocol=protocol,
        vpc_id=vpc_id,
        target_type='instance',
        health_check=lb.TargetGroupHealthCheckArgs(
            port=health_check_port,
            protocol=protocol,
            interval=30,
            timeout=10,
            healthy_threshold=3,
            unhealthy_threshold=3,
        ),
        tags={'Name': f'nixos-cloud-tg{name_suffix}-{stack_name}'}
    )
    return target_group

def create_listener(load_balancer_arn, port, protocol, target_group_arn, name_suffix=""):
    """Create a listener for the load balancer"""
    suffix = f"-{name_suffix}" if name_suffix else ""

    listener = lb.Listener(
        f'nixos-cloud-listener{suffix}',
        load_balancer_arn=load_balancer_arn,
        port=port,
        protocol=protocol,
        default_actions=[lb.ListenerDefaultActionArgs(
            type='forward',
            target_group_arn=target_group_arn
        )]
    )
    return listener

def attach_targets_to_target_group(target_group_arn, instance_ids, port, target_suffix=""):
    """Attach EC2 instances to a target group"""
    suffix = f"-{target_suffix}" if target_suffix else ""

    target_attachments = []
    for i, instance_id in enumerate(instance_ids, start=1):
        attachment = lb.TargetGroupAttachment(
            f'nixos-cloud-tg-attachment{suffix}-{i}',
            target_group_arn=target_group_arn,
            target_id=instance_id,
            port=port
        )
        target_attachments.append(attachment)

    return target_attachments
