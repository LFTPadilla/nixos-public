import pulumi
from pulumi_aws import cloudwatch, xray
import json

def create_xray_sampling_rule(stack_name):
    """Create an X-Ray sampling rule for tracing"""
    sampling_rule = xray.SamplingRule(
        f'nixos-cloud-xray-sampling',
        rule_name=f'nixos-cloud-{stack_name}-sampling-rule',
        priority=1000,
        version=1,
        reservoir_size=1,
        fixed_rate=0.05,
        host="*",
        http_method="*",
        url_path="*",
        service_name="*",
        service_type="*",
        resource_arn="*"
    )
    return sampling_rule

def create_cloudwatch_dashboard(aws_region, instance_ids, east_region, project_name, environment, stack_name):
    """Create a CloudWatch dashboard for monitoring EC2 instances"""
    dashboard_config = {
        "widgets": [
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/EC2", "CPUUtilization", "InstanceId", inst_id]
                        for inst_id in instance_ids
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": aws_region,
                    "title": "EC2 CPU Utilization"
                }
            },
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/EC2", "NetworkIn", "InstanceId", inst_id]
                        for inst_id in instance_ids
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": aws_region,
                    "title": "EC2 Network In"
                }
            },
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/EC2", "NetworkOut", "InstanceId", inst_id]
                        for inst_id in instance_ids
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": aws_region,
                    "title": "EC2 Network Out"
                }
            },
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/EC2", "MemoryUtilization", "InstanceId", inst_id]
                        for inst_id in instance_ids
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": aws_region,
                    "title": "EC2 Memory Utilization"
                }
            },
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/EC2", "StatusCheckFailed", "InstanceId", inst_id]
                        for inst_id in instance_ids
                    ],
                    "period": 300,
                    "stat": "Sum",
                    "region": aws_region,
                    "title": "EC2 Status Check Failed"
                }
            },
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/WAFV2", "BlockedRequests", "WebACL", f"{project_name}-waf-{environment}", "Rule", "ALL"]
                    ],
                    "period": 300,
                    "stat": "Sum",
                    "region": east_region,
                    "title": "WAF Blocked Requests"
                }
            }
        ]
    }

    dashboard = cloudwatch.Dashboard(
        'nixos-cloud-dashboard',
        dashboard_name=f'nixos-cloud-{stack_name}-dashboard',
        dashboard_body=json.dumps(dashboard_config)
    )
    return dashboard

def create_instance_alarms(instances, stack_name):
    """Create CloudWatch alarms for EC2 instances"""
    alarms = []
    for i, instance in enumerate(instances, start=1):
        alarm = cloudwatch.MetricAlarm(
            f'cpu-alarm-{i}',
            name=f'nixos-cloud-{stack_name}-cpu-alarm-{i}',
            comparison_operator="GreaterThanThreshold",
            evaluation_periods=2,
            metric_name="CPUUtilization",
            namespace="AWS/EC2",
            period=300,
            statistic="Average",
            threshold=90.0,
            alarm_description="CPU usage above 80%",
            dimensions={
                "InstanceId": instance.id
            }
        )
        alarms.append(alarm)
    return alarms
