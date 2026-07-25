# Private Configuration Files

## Setup Instructions

1. **Private Hosts**: Copy `example.private-hosts.nix` to `private-hosts.nix` and add your actual development hosts and production IPs
2. **Home Assistant**: See `users/felipe/homeassistant/README.md` for HA setup

## Files to Keep Private

- `system/private-hosts.nix` - Your actual development hosts and production server IPs
- `users/felipe/homeassistant/hacompanion.toml` - Your actual HA token and IPs

These files are automatically gitignored to prevent accidental commits of sensitive data.