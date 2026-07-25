# OpenClaw Gateway Password Setup

## ⚠️ SECURITY NOTE

The gateway password has been **intentionally removed** from this repository to prevent accidental credential leakage.

### How to Set Your Gateway Password

1. **Generate a strong password** (recommended 16+ characters):
   ```bash
   openssl rand -base64 32 | head -c 24
   ```

2. **Set it in your local `openclaw.json`:**
   ```bash
   openclaw config.set gateway.auth.password "YOUR_GENERATED_PASSWORD"
   ```

3. **Verify it's set:**
   ```bash
   openclaw status
   ```

4. **Never commit this password** to any repository. Add to `.gitignore` if needed.

### For Team Deployments

If multiple people need access to the gateway:
- Use a secure secrets manager (e.g., 1Password, Vault, AWS Secrets Manager)
- Store the password in your CI/CD pipeline secrets, not in Git
- Rotate passwords regularly

### Default Behavior

If no password is set, the gateway will use **password authentication mode** but require you to set one before first run.

---

See `openclaw --help` for more configuration options.
