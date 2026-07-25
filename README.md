# Felipe's multi-host dotfiles

Nix flake repository for declarative personal environments across NixOS, Ubuntu
with Home Manager, macOS with nix-darwin, and infrastructure definitions. It
is not a single-machine NixOS configuration.

This public edition intentionally omits private host inventories, SSH/network
routes, customer-specific sessions, Kubernetes/Proxmox state, secret-routing
profiles, and local recovery material. `.public-export-denylist` is enforced by
CI so those paths cannot be reintroduced accidentally.

## Host map

| Target | Platform | Purpose | Apply command |
| --- | --- | --- | --- |
| `ubuntu-dev` | Ubuntu + Nix + Home Manager | Current Ubuntu development host (`hostname`: `ubuntu`) | `nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev` |
| `ubuntu-cli` | Ubuntu + Nix + Home Manager | Compatibility alias for `ubuntu-dev` | Same as above |
| `default-msi`, `default-hp`, `default`, `main` | NixOS | Personal NixOS machines | `sudo nixos-rebuild switch --flake .#<target>` |
| `mac` | macOS + nix-darwin | macOS workstation | `darwin-rebuild switch --flake .#mac` |

The flake target name is an environment identifier; it does not need to match
`hostnamectl`. In particular, this Ubuntu host is intentionally configured by
the `ubuntu-dev` target while its hostname remains `ubuntu`.

## Repository layout

```text
flake.nix                  Entrypoints and host outputs
hosts/                     Small host-specific modules
system/                    Shared NixOS and Home Manager modules, scripts, packages
users/felipe/              User-scoped Home Manager modules and integrations
export/                    Editable configs linked into $HOME by Home Manager
docs/                      Operational documentation
deploy/                    Sanitized infrastructure examples
```

The normal composition rule is: put reusable user configuration in
`users/felipe/home-modules/` or `system/`, and keep `hosts/<name>/` limited to
real host differences. The `ubuntu-dev` host imports `system/home-terminal.nix`,
which in turn owns the shared shell, tmux, editor, and tmuxinator setup.

## Current Ubuntu development host

This is the non-NixOS target for the active Ubuntu host. It installs a
Nix-managed CLI environment while leaving Ubuntu responsible for the kernel,
desktop, GPU stack, and system services.

```bash
cd ~/.dotfiles

# Evaluate and build only; does not activate a generation.
nix run nixpkgs#home-manager -- build --flake .#ubuntu-dev

# Activate after a successful build.
nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev
```

`system/scripts/rebuild` auto-detects the OS and invokes the corresponding
switch command. It does not modify tracked files by default. Formatting is
explicit: `DOTFILES_FORMAT=1 bash system/scripts/rebuild`.

More detail: [docs/ubuntu-cli-dev.md](docs/ubuntu-cli-dev.md).

## Validation

Run validation before applying a change:

```bash
# Fast evaluation of the active Ubuntu target
nix eval --json .#homeConfigurations.ubuntu-dev.config.home.username
nix run nixpkgs#home-manager -- build --flake .#ubuntu-dev

# Cross-host evaluation when the local Nix store is healthy
nix flake check --no-build

# Shell syntax for repository scripts
bash -n system/scripts/rebuild
```

A Home Manager build creates or refreshes the local `result` link; `.gitignore`
excludes it. Review `git diff --check` and `git status --short` before a
switch or commit.

## Editable configurations and ownership

`export/` and selected repository files are deliberately linked into `$HOME`
with `mkOutOfStoreSymlink`. This makes edits immediately visible but requires
that the checkout stays at `~/.dotfiles` on hosts that use these links.
Examples include the public tmuxinator project and Neovim configuration.

Generated outputs, Python bytecode, package managers, and operating-system
metadata do not belong in the repository. Keep user data and application
caches out of this tree.

## Secrets and recovery

Do not add credentials, tokens, private keys, or authentication caches to this
repository. Use 1Password or another secret manager; local fallback files must
be ignored and permission-restricted. Review `.gitignore` and
[PUBLISH_CHECKLIST.md](PUBLISH_CHECKLIST.md) before sharing the repository.

Historical rescue material belongs in a local, permission-restricted archive
outside this repository. It is never active configuration and is excluded from
Git because rescue snapshots commonly contain generated payloads or
authentication caches. Never import rescue files into an active host without
comparing them against the currently managed modules.

For a failed Home Manager activation, select an earlier generation with
`home-manager generations` and activate that generation. For NixOS hosts, use
the boot menu or `sudo nixos-rebuild switch --rollback`.
