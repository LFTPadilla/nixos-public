# nixos-anywhere-examples

Checkout the [flake.nix](flake.nix) for examples tested on different hosters.

verify if you have access in the security groups

Before building check the disk
lsblk

in this case is nvme0n1, replace it on disk-config.nix

Use this for all other targets

nixos-anywhere --flake .#generic --generate-hardware-config nixos-generate-config ./hardware-configuration.nix <hostname>

## First build
`nix run nixpkgs#nixos-anywhere -- \
--flake .#nixos-installer \
--generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
-i ~/.ssh/nixos-cloud-desktop-key.pem \
--ssh-option "IdentitiesOnly=yes" \
--ssh-option "StrictHostKeyChecking=no" \
--target-host ubuntu@nixos-cloud`


## First build proxmox
nixos-anywhere --flake ".#nixos-installer" --generate-hardware-config nixos-generate-config ./hardware-configuration.nix -i ~/.ssh/homeserver --ssh-option "IdentitiesOnly=yes" --ssh-option "StrictHostKeyChecking=no" --target-host root@192.168.5.10
NIX_SSHOPTS='-i ~/.ssh/homeserver -o IdentitiesOnly=yes -o StrictHostKeyChecking=no' nixos-rebuild switch --flake .#nixos-installer --target-host root@192.168.5.95



## build on local

NIX_SSHOPTS='-i ~/.ssh/nixos-cloud-desktop-key.pem -o IdentitiesOnly=yes -o StrictHostKeyChecking=no' nixos-rebuild switch --flake .#nixos-installer --target-host root@nixos-cloud

## Build on the remote host (avoids local building)

NIX_SSHOPTS='-i ~/.ssh/nixos-cloud-desktop-key.pem -o IdentitiesOnly=yes -o StrictHostKeyChecking=no' nixos-rebuild switch --flake .#nixos-installer --target-host root@nixos-cloud --build-host root@nixos-cloud



# nixos-cloud Infrastructure Overview

This vault page documents the AWS infrastructure for the nixos-cloud project: a cloud workstation for development and a hands‑on environment for AWS Cloud Practitioner learning.

## Summary
- VPC with CIDR `10.0.0.0/16`
- Two public subnets across AZs: `10.0.1.0/24` (AZ a) and `10.0.2.0/24` (AZ b)
- Internet Gateway + public route table (`0.0.0.0/0 -> IGW`)
- One EC2 instance (NixOS) in Public Subnet 1 with an Elastic IP
- Security Group: inbound restricted to your IP (configurable), all egress allowed
- IAM instance role with `AmazonSSMManagedInstanceCore`
- SSM Agent enabled on NixOS for Session Manager access
- DNS: Route 53 A record -> Elastic IP (optional)
- No NAT Gateway, no private subnets (kept minimal and cost‑effective)
- Load balancer / CDN / RDS reserved for future use

## Diagram
- Excalidraw file: `deploy/infrastructure/aws/diagram/nixos-cloud.excalidraw`
  - Open at https://excalidraw.com → Open → select the file

## Components
- VPC
  - Name: `nixos-cloud-vpc-<stack>`
  - CIDR: `10.0.0.0/16`
- Subnets
  - Public Subnet 1: `10.0.1.0/24` (AZ a)
  - Public Subnet 2: `10.0.2.0/24` (AZ b)
- Routing
  - Internet Gateway: attached to VPC
  - Public Route Table: default route `0.0.0.0/0 -> IGW`; associated to both public subnets
- Compute
  - EC2: NixOS, launched in Public Subnet 1, associated Elastic IP
  - SSM Agent enabled for Session Manager
- Security
  - Security Group allows inbound only from your IP (SSH by default). HTTP/HTTPS can be enabled from your IP by uncommenting rules.
  - Outbound: all traffic allowed
  - IMDSv2 can be enforced later (optional hardening)
- IAM
  - Instance role: includes `AmazonSSMManagedInstanceCore` managed policy

## Access
- Session Manager (recommended)
  - `aws ssm start-session --target <instance-id> --profile nixos-deployer`
- SSH (root)
  - Pulumi output `ssh_command` provides a ready command
  - Example: `ssh -i ~/.ssh/<key>.pem root@<elastic-ip>`
- DNS
  - Create a Route 53 A record pointing to the Elastic IP

## Deploy & Operate
- Dev shell
  - `cd deploy/infrastructure && nix develop`
  - Uses `AWS_PROFILE=nixos-deployer` and installs Python/Pulumi deps
- Pulumi
  - `cd deploy/infrastructure/aws`
  - Configure stack (example stack file provided): `Pulumi.dev2.yaml`
    - Keys: `aws:region`, `aws:profile`, `nixos-cloud:ami_ec2`, `nixos-cloud:availability_zone`, `nixos-cloud:allowed_cidr`
  - Deploy: `pulumi up`
- Flake (remote install path used by scripts)
  - `deploy/nixos-cloud/flake.nix` exports `nixosConfigurations.nixos-installer`
- NixOS config highlights
  - `deploy/nixos-cloud/configuration.nix`
    - Tailscale enabled, Docker enabled, toolchain packages
    - `services.amazon-ssm-agent.enable = true;`

## Security Posture
- Inbound minimized: SG restricted to your IP (config: `nixos-cloud:allowed_cidr`)
- SSM enabled: allows SSH‑less administration
- No public LB; no NAT Gateway; no private subnets (for now)
- Future hardening options:
  - Enforce IMDSv2 and hop limit 1
  - Move SSH to SSM‑only (drop port 22 entirely)
  - VPC Flow Logs + CloudWatch/Athena queries
  - GuardDuty, AWS Config rules, Security Hub

## Cost Notes
- Current baseline (without EC2): $0/month
- With EC2 + Elastic IP: instance cost + ~$3.65/month for public IPv4
- No NAT Gateway (saves ~$33+/month)
- Additional costs only when you add LBs, NAT, interface endpoints, etc.

## Future Expansions
- Load Balancer (ALB/NLB) and CloudFront/WAF (modules prepared)
- Private subnets + NAT (or VPC endpoints) if you need private workloads
- EFS for persistent home/data and multi‑AZ mounts
- Budgets/alerts, snapshot lifecycle, Route 53 health checks

## Key Files
- Pulumi stack: `deploy/infrastructure/aws/__main__.py`
- Networking module: `deploy/infrastructure/aws/modules/network.py`
- Security group module: `deploy/infrastructure/aws/modules/security.py`
- IAM module: `deploy/infrastructure/aws/modules/iam.py`
- Compute module: `deploy/infrastructure/aws/modules/compute.py`
- Dev shell: `deploy/infrastructure/shell.nix`
- Stack config example: `deploy/infrastructure/aws/Pulumi.dev2.yaml`
- NixOS flake & config: `deploy/nixos-cloud/flake.nix`, `deploy/nixos-cloud/configuration.nix`
