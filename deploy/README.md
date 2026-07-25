# Deploy

Cloud/infra deployment targets.

## Layout

| Dir | What | Status |
|-----|------|--------|
| `infrastructure/aws/` | **Pulumi (Python) IaC** — VPC, compute, IAM, LB, monitoring. See its README. | Active |
| `nixos-cloud/` | nixos-anywhere target for `nixos-aws` / `nixos-installer` flake outputs (configuration, disko, docker-compose servers). Install commands in its README. | Active |
| `iam-policy.json`, `iam-setup-guide.md` | IAM bootstrap for Pulumi | Reference |
| `graviton-cost-analysis.md` | Instance cost notes | Reference |

## Usage

```bash
# AWS infra (Pulumi)
cd ~/.dotfiles/deploy/infrastructure/aws && pulumi up

# NixOS install to a fresh machine (Proxmox VM or EC2)
# see deploy/nixos-cloud/README.md for nixos-anywhere commands
```

Historical note: a CloudFormation-based workflow existed here until 2025; replaced by Pulumi.
