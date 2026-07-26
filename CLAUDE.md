# CLAUDE.md

Guidance for Claude Code in this repo.

**Read `AGENTS.md`** — current workflows (rebuild, vault-skills-sync, mcp-sync) and repo conventions. **Read `README.md`** — flake outputs, host table, validation commands.

Multi-host Nix flake at repo root: NixOS (`default-msi`/`hp`, `nixos-proxmox`, `gmk`, `wilson-lightnode`, `blackrack-k3s-worker`, `nixos-aws`), home-manager (`ubuntu-dev`, `wilson`), nix-darwin (`mac`).

Quick reference:
- Rebuild NixOS: `sudo nixos-rebuild switch --flake ~/.dotfiles#<host>` (alias `rebuild`)
- Home Manager (this Ubuntu VM): `home-manager switch --flake ~/.dotfiles#ubuntu-dev`
- Flake ops run at repo root: `nix flake check ~/.dotfiles`
- Proxmox host files (`pve/`) are NOT Nix — synced via `pve/sync.sh` to pve-main (192.168.5.190)
- Ops docs: `docs/` (tmux, nvim, hyprland, ubuntu-cli-dev)
