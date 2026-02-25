# NixOS Repository Publication Checklist ✅

This document outlines all security & cleanup steps taken before publishing this repo.

## ✓ Items Removed/Protected

### 1. **Gateway Password** ✅
- **File:** `openclaw.json` (not in repo)
- **Action:** Removed from repository
- **Setup:** See `GATEWAY_PASSWORD_SETUP.md`
- **Why:** Credentials should never be committed to Git

### 2. **Pulumi AWS Configuration** ✅
- **File:** `deploy/infrastructure/aws/Pulumi.dev.yaml`
- **Action:** Added to `.gitignore`
- **Why:** Contains AWS profile names, IP CIDR blocks, AMI IDs
- **Setup:** Use `Pulumi.dev.yaml.example` as template

### 3. **Encrypted Secrets (git-crypt)** ✅
- **File:** `system/private-hosts.nix`
- **Status:** Already encrypted via `git-crypt`
- **Contains:** Private IP mappings, local hostnames
- **Access:** Requires encryption key to decrypt
- **Public View:** Shows as binary/encrypted data

### 4. **Home Assistant Configuration** ✅
- **File:** `users/felipe/homeassistant/hacompanion.example.toml`
- **Status:** Example file provided, real file ignored
- **Why:** Contains API tokens, device credentials

### 5. **Docker Compose Secrets** ✅
- **Files:** `docker-compose.yml` in various locations
- **Check:** Manual review before publishing
- **Items to verify:**
  - No hardcoded passwords in env files
  - No exposed API keys
  - No private Docker registry credentials

## 🔒 Still Protected (Encrypted)

```
system/private-hosts.nix          [git-crypt ✓]
```

Add to this list as needed:
```bash
# Encrypt additional files
git-crypt add-user KEYID FILE
echo "new-file filter=git-crypt diff=git-crypt" >> .gitattributes
```

## 📋 Files to Review Before Publishing

- [ ] `deploy/infrastructure/aws/Pulumi.yaml` - verify no real AWS IDs
- [ ] `hosts/*/configuration.nix` - check for hardcoded IPs/hostnames
- [ ] `deploy/iam-policy.json` - verify it's sanitized/example
- [ ] `deploy/iam-setup-guide.md` - review for real account details
- [ ] All `docker-compose.yml` files - no exposed secrets
- [ ] Beszel fingerprint file - check permissions/contents

## 🚀 Publishing Steps

### For Initial Clean Copy:
```bash
# Create new bare repo (no history)
mkdir ~/nixos-public
cd ~/nixos-public
git init --bare .

# Or clone with no history:
git clone --depth=1 nixos nixos-public
cd nixos-public
git filter-branch --prune-empty -- --all  # Remove all history
```

### Before Push:
```bash
# Verify what will be published
git ls-files | grep -E "(password|secret|key|token|cred)"

# Check for large files
git rev-list --all --objects --disk-usage | sort -k2 -rn | head -20

# Verify git-crypt status
git-crypt ls-files
```

### After Publish:
```bash
# Tag release
git tag -a v1.0 -m "Initial public release"

# Update README with:
# - Setup instructions
# - Prerequisites (NixOS version, flake support)
# - How to customize for your system
```

## 🔐 Git-Crypt Setup for Collaborators

```bash
# Add collaborator's GPG key
git-crypt add-user YOUR_KEYID

# Existing users unlock with:
git-crypt unlock /path/to/keyfile
```

## ⚠️ Security Best Practices

1. **Never commit secrets** - use `.gitignore` + environment variables
2. **Use `git-crypt` for configs** that must be in repo but are sensitive
3. **Rotate credentials** after any accidental commit
4. **Review diffs carefully** before pushing: `git diff HEAD~1`
5. **Use pre-commit hooks** to catch secrets:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

## 📚 References

- [git-crypt docs](https://github.com/AGWA/git-crypt)
- [Pre-commit framework](https://pre-commit.com/)
- [OWASP Secret Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Last updated:** 2026-02-24
**Status:** ✅ Ready for publication (pending final review)
