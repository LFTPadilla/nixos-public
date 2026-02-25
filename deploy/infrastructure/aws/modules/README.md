# AWS Infrastructure with Pulumi (nixos-cloud)

This directory contains Pulumi code for deploying AWS infrastructure in a modular, maintainable way.

## Modular Structure

The infrastructure code has been split into focused modules, making it easier to maintain and extend:

```
infrastructure/pulumi/aws/
├── __main__.py              # Main entry point that coordinates all modules
└── modules/                 # Directory containing all modular components
    ├── __init__.py          # Makes the directory a Python package
    ├── network.py           # VPC, subnets, routing resources
    ├── security.py          # Security groups and related resources
    ├── iam.py               # IAM roles and policies
    ├── compute.py           # EC2 instances and EFS storage
    ├── loadbalancer.py      # (Reserved) Load balancers, target groups, and listeners
    ├── cdn.py               # (Reserved) CloudFront and WAF resources
    └── monitoring.py        # CloudWatch dashboards and alarms
```

## Benefits of This Structure

- **Improved Maintainability**: Each file has a clear responsibility and scope
- **Code Reusability**: Modules can be reused across different Pulumi stacks
- **Easier Testing**: Smaller components are easier to test in isolation
- **Better Collaboration**: Multiple team members can work on different modules without conflicts
- **Improved Readability**: Shorter files with focused logic are easier to understand

## How the Modules Work Together

The `__main__.py` file coordinates all modules, importing them and using their functions to create resources. Each module exports functions that create specific infrastructure components with clear parameters and return values.

## Usage

Run Pulumi commands from the `deploy/infrastructure/aws` directory:

```bash
# Preview changes
pulumi preview

# Deploy infrastructure
pulumi up

# Destroy infrastructure (use with caution!)
pulumi destroy
```

## Configuration

The Pulumi stack configuration supports the following settings:

- `environment`: Deployment environment (e.g., staging, production)
- `region`: AWS region to deploy to (defaults to provider region)
- `availability_zone`: Specific AZ for resources that require it
- `ami_ec2`: AMI ID for EC2 instances
- `project_name`: Project name used for resource naming (defaults to 'nixos-cloud')

## Load Balancer and CDN (Future)

NLB/CloudFront modules are kept reserved for future use and are not active in the current nixos-cloud stack.

## Connecting to Infrastructure

### SSH Access

Pulumi exports an `ssh_command` output for the first instance, using the NixOS default root user.

Database resources are not deployed in the current stack.
