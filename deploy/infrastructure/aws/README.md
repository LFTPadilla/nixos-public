# Pulumi Infrastructure (nixos-cloud)

This directory contains Pulumi code for managing AWS infrastructure for the nixos-cloud environment.

## Stack Structure

The current stack focuses on core infrastructure:

- **Main Infrastructure Stack** (`__main__.py`): VPC, networking, security groups, EC2 instance(s), and monitoring. Load balancer/CDN modules are reserved for future use and are not active.

## Deploying the Stacks

### Main Infrastructure Stack

To deploy the main infrastructure:

```bash
cd deploy/infrastructure/aws

export AWS_PROFILE=nixos-deployer
pulumi up
```

The main stack exports:
- `vpc_id`: VPC ID
- `vpc_cidr`: VPC CIDR
- `public_ips`: List of instance public IPs
- `public_dns`: List of instance public DNS names
- `ssh_command`: Command for SSH access to the first instance (root@)

### CDN / Load Balancer (future)
Modules exist but are not enabled in the current stack.

## Stack Outputs

### Main Stack Outputs
- `vpc_id`: VPC ID
- `vpc_cidr`: VPC CIDR
- `public_ips`: List of EC2 instance public IPs
- `public_dns`: List of EC2 instance public DNS names
- `ssh_command`: SSH command for accessing the primary instance (root@)


## Stack Dependencies

No CDN stack dependencies at the moment.

## Updating Stacks

Update the infrastructure with `pulumi up`.
