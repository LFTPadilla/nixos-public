# IAM Setup Guide for NixOS Cloud Deployment

## Required AWS Permissions

### Option 1: Create IAM User (Recommended for Personal Use)

#### Step 1: Create IAM Policy
```bash
# Create the policy using AWS CLI
aws iam create-policy \
    --policy-name NixOSCloudDeployment \
    --policy-document file://iam-policy.json \
    --description "Permissions for NixOS cloud server deployment and management"
```

#### Step 2: Create IAM User
```bash
# Create user
aws iam create-user --user-name nixos-deployer

# Attach policy to user
aws iam attach-user-policy \
    --user-name nixos-deployer \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/NixOSCloudDeployment

# Create access keys
aws iam create-access-key --user-name nixos-deployer
```

#### Step 3: Configure AWS CLI
```bash
# Configure with the new access keys
aws configure
# Enter the Access Key ID and Secret Access Key from previous step
# Default region: us-east-1
# Default output format: json
```

### Option 2: Create IAM Role (For EC2/Lambda)

If you're running the deployment from another EC2 instance:

```bash
# Create trust policy for EC2
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

# Create role
aws iam create-role \
    --role-name NixOSDeploymentRole \
    --assume-role-policy-document file://trust-policy.json

# Attach policy to role
aws iam attach-role-policy \
    --role-name NixOSDeploymentRole \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/NixOSCloudDeployment

# Create instance profile
aws iam create-instance-profile --instance-profile-name NixOSDeploymentRole
aws iam add-role-to-instance-profile \
    --instance-profile-name NixOSDeploymentRole \
    --role-name NixOSDeploymentRole
```

## Minimal Permissions Breakdown

### **Core EC2 Permissions** (Required)
```json
{
    "EC2 Instance Management": [
        "ec2:RunInstances",
        "ec2:StartInstances", 
        "ec2:StopInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances"
    ],
    "Security Groups": [
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:DescribeSecurityGroups"
    ],
    "Key Pairs": [
        "ec2:CreateKeyPair",
        "ec2:DescribeKeyPairs"
    ]
}
```

### **Cost Optimization Permissions** (Optional)
```json
{
    "Cost Monitoring": [
        "ce:GetCostAndUsage",
        "budgets:ViewBudget"
    ],
    "Scheduling": [
        "events:PutRule",
        "events:PutTargets"
    ]
}
```

### **Advanced Features** (Optional)
```json
{
    "Monitoring": [
        "cloudwatch:GetMetricStatistics",
        "logs:CreateLogGroup"
    ],
    "Elastic IPs": [
        "ec2:AllocateAddress",
        "ec2:AssociateAddress"
    ]
}
```

## Security Best Practices

### 1. **Use Temporary Credentials**
```bash
# For development, use temporary credentials
aws sts get-session-token --duration-seconds 3600
```

### 2. **Restrict by Resource Tags**
Add resource-based restrictions to your policy:
```json
{
    "Effect": "Allow",
    "Action": "ec2:*",
    "Resource": "*",
    "Condition": {
        "StringEquals": {
            "ec2:ResourceTag/Purpose": "nixos-development"
        }
    }
}
```

### 3. **IP Address Restrictions**
Restrict access to your IP:
```json
{
    "Effect": "Allow",
    "Action": "*",
    "Resource": "*",
    "Condition": {
        "IpAddress": {
            "aws:SourceIp": "YOUR_IP_ADDRESS/32"
        }
    }
}
```

### 4. **MFA Requirements**
```json
{
    "Effect": "Deny",
    "Action": "*",
    "Resource": "*",
    "Condition": {
        "BoolIfExists": {
            "aws:MultiFactorAuthPresent": "false"
        }
    }
}
```

## Alternative: AWS SSO (Recommended for Organizations)

If you have AWS Organizations:

1. **Enable AWS SSO**
2. **Create Permission Set** with the NixOSCloudDeployment policy
3. **Assign to Users/Groups**
4. **Access via**: `aws sso login`

## Cost Implications

### IAM Costs
- **IAM Users/Roles**: Free
- **Access Keys**: Free  
- **MFA Devices**: Free
- **AWS SSO**: Free for up to 5 users

### Resource Costs with These Permissions
- **EC2 Instances**: Variable (see cost-optimization.md)
- **EBS Storage**: ~$0.10/GB/month
- **Elastic IP**: $0.005/hour when not associated
- **CloudWatch**: First 10 metrics free

## Testing Your Permissions

### Quick Test Script
```bash
#!/bin/bash
# Test essential permissions

echo "Testing IAM permissions..."

# Test 1: Check identity
aws sts get-caller-identity || echo "❌ STS permissions failed"

# Test 2: List instances
aws ec2 describe-instances --region us-east-1 || echo "❌ EC2 describe failed"

# Test 3: Check images
aws ec2 describe-images --owners 080433136561 --region us-east-1 --max-items 1 || echo "❌ Image access failed"

# Test 4: Check security groups  
aws ec2 describe-security-groups --region us-east-1 --max-items 1 || echo "❌ Security group access failed"

echo "✅ Permission test completed"
```

## Troubleshooting Common Issues

### **Access Denied Errors**
```bash
# Check what permissions you actually have
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USERNAME
aws iam get-policy-version --policy-arn POLICY_ARN --version-id v1
```

### **Region Issues**
```bash
# Ensure you're using the correct region
aws configure get region
aws configure set region us-east-1
```

### **Resource Limits**
```bash
# Check service quotas
aws service-quotas get-service-quota \
    --service-code ec2 \
    --quota-code L-1216C47A  # Running On-Demand instances
```

## Quick Setup Commands

### For New AWS Account:
```bash
# 1. Install AWS CLI
nix-shell -p awscli2

# 2. Create policy
aws iam create-policy --policy-name NixOSCloudDeployment --policy-document file://iam-policy.json

# 3. Create user and attach policy
aws iam create-user --user-name nixos-deployer
aws iam attach-user-policy --user-name nixos-deployer --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/NixOSCloudDeployment

# 4. Create access keys
aws iam create-access-key --user-name nixos-deployer

# 5. Configure CLI
aws configure
```

### For Existing User:
```bash
# Just attach the policy
aws iam attach-user-policy \
    --user-name YOUR_EXISTING_USER \
    --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/NixOSCloudDeployment
```

## Security Checklist

- [ ] ✅ Created dedicated IAM user for deployments
- [ ] ✅ Attached minimal required permissions
- [ ] ✅ Enabled MFA (if possible)
- [ ] ✅ Restricted source IP addresses
- [ ] ✅ Set up access key rotation schedule
- [ ] ✅ Configured AWS CLI with user credentials
- [ ] ✅ Tested permissions with test script
- [ ] ✅ Documented access keys securely

Now you're ready to deploy with proper IAM permissions! 🚀