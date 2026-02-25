# NixOS Cloud Desktop Deployment

Deploy your NixOS dotfiles to AWS cloud for powerful remote development accessible from anywhere.

## 🚀 Quick Start

### Prerequisites
```bash
# Install AWS CLI
nix-shell -p awscli2

# Configure AWS credentials
aws configure
```

### Deploy
```bash
cd ~/.dotfiles/deploy
./cloudformation-deploy.sh deploy
```

## 📋 What Gets Created

### Infrastructure (CloudFormation)
- **VPC** with public/private subnets
- **Security Groups** (SSH + Tailscale only)
- **EC2 Instance** with your chosen specs
- **Elastic IP** for consistent access
- **IAM Roles** with minimal permissions
- **CloudWatch Monitoring** and cost alerts

### Software (NixOS)
- **Your complete dotfiles** environment
- **Tailscale VPN** for secure access
- **Sunshine** for remote desktop streaming
- **Development tools** (git, neovim, etc.)

## 💰 Cost Management

### Start/Stop for Savings
```bash
# Stop instance (save ~70% costs)
./cloudformation-deploy.sh stop

# Start when needed
./cloudformation-deploy.sh start
```

### Instance Types for Colombia
| Type | vCPU | RAM | Cost/Month (8h/day) | Use Case |
|------|------|-----|---------------------|----------|
| c5.large | 2 | 4GB | ~$20 | Light development |
| c5.xlarge | 4 | 8GB | ~$40 | Standard development |
| c5.2xlarge | 8 | 16GB | ~$80 | Heavy workloads |

## 🔒 Security Features

- **No public Sunshine ports** - only accessible via Tailscale
- **SSH key authentication** only
- **Encrypted EBS storage**
- **VPC isolation**
- **Your IP whitelisted** for SSH

## 🎮 Remote Desktop Access

### Via Tailscale (Recommended)
1. Deploy server: `./cloudformation-deploy.sh deploy`
2. Get Tailscale IP from deployment output
3. Access: `https://TAILSCALE_IP:47984`

### Via SSH Tunnel (Alternative)
```bash
# Create tunnel
ssh -L 47984:localhost:47984 felipe@YOUR_SERVER_IP

# Access locally
https://localhost:47984
```

## 📊 Management Commands

```bash
# Check status
./cloudformation-deploy.sh status

# Instance management
./cloudformation-deploy.sh start|stop|reboot

# View outputs
./cloudformation-deploy.sh outputs

# Complete cleanup
./cloudformation-deploy.sh cleanup
```

## 🛠 Customization

### Environment Variables
```bash
# Custom instance type
INSTANCE_TYPE=c5.xlarge ./cloudformation-deploy.sh deploy

# Larger storage
VOLUME_SIZE=100 ./cloudformation-deploy.sh deploy

# Custom stack name
STACK_NAME=my-desktop ./cloudformation-deploy.sh deploy
```

### Configuration Files
- `nixos-cloud-infrastructure.yaml` - CloudFormation template
- `cloud-server.nix` - NixOS configuration
- `cloudformation-deploy.sh` - Deployment script

## 📈 Monitoring

### CloudWatch Dashboard
- CPU, memory, network metrics
- Cost tracking and alerts
- Instance status monitoring

### Cost Budgets
- Automatic monthly budget alerts
- Usage tracking by resource tags
- Cost optimization recommendations

## 🌍 Regional Optimization

**For Colombia**: Uses `us-east-1` by default (best latency/cost)

To use different region:
```bash
AWS_REGION=us-west-2 ./cloudformation-deploy.sh deploy
```

## 🔧 Troubleshooting

### Common Issues

**"No default VPC"** ✅ Solved - Creates complete VPC infrastructure

**Permission errors**:
```bash
# Check IAM permissions
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name YOUR_USER
```

**SSH connection fails**:
```bash
# Check security group allows your IP
./cloudformation-deploy.sh status
```

**NixOS deployment fails**:
```bash
# Check instance is ready
aws ec2 describe-instances --instance-ids INSTANCE_ID
```

### Logs and Debugging
```bash
# CloudFormation events
aws cloudformation describe-stack-events --stack-name nixos-cloud-desktop

# Instance logs
aws ec2 get-console-output --instance-id INSTANCE_ID
```

## 🎯 Use Cases

### Remote Development
- Code on powerful cloud instances
- Access from low-power devices (Raspberry Pi, tablets)
- Consistent environment across locations

### Streaming Development
- Stream coding sessions via Sunshine
- High-quality 1080p@60fps experience
- Low latency for Colombia (~80-120ms)

### Cost-Effective Computing
- Pay-as-you-use model
- Stop when not needed
- Scale up/down based on workload

## 📝 Example Workflow

1. **Morning**: Start instance (`./cloudformation-deploy.sh start`)
2. **Development**: Connect via Tailscale to Sunshine desktop
3. **Evening**: Stop instance (`./cloudformation-deploy.sh stop`)
4. **Weekend**: Keep stopped, only pay for storage

**Monthly cost**: ~$15-40 depending on usage and instance type

---

Your powerful cloud development environment awaits! 🚀