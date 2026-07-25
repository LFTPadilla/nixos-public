# Felipe's multi-host dotfiles

Nix flake repository for declarative personal environments across NixOS, Ubuntu
with Home Manager, macOS with nix-darwin, and infrastructure definitions. It
is not a single-machine NixOS configuration.

## Host map

| Target | Platform | Purpose | Apply command |
| --- | --- | --- | --- |
| `ubuntu-dev` | Ubuntu + Nix + Home Manager | Current Ubuntu development host (`hostname`: `ubuntu`) | `nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev` |
| `ubuntu-cli`, `ubuntu-24` | Ubuntu + Nix + Home Manager | Compatibility aliases for `ubuntu-dev` | Same as above |
| `default-msi`, `default-hp`, `default`, `main` | NixOS | Personal NixOS machines | `sudo nixos-rebuild switch --flake .#<target>` |
| `mac` | macOS + nix-darwin | macOS workstation | `darwin-rebuild switch --flake .#mac` |
| `nixos-proxmox`, `gmk` | NixOS | Dedicated NixOS hosts | `sudo nixos-rebuild switch --flake .#<target>` |
| `wilson` | Ubuntu + Home Manager | Lightweight remote user environment | `nix run nixpkgs#home-manager -- switch --flake .#wilson` |
| `wilson-lightnode` | NixOS + disko | Blackrack client VPS (Lightnode, Bogotá) | `nixos-anywhere --flake .#wilson-lightnode root@<ip>` |
| `blackrack-k3s-worker` | NixOS + disko | k3s worker hosting the OpenClaw gateways | `nixos-anywhere --flake .#blackrack-k3s-worker root@<ip>` |
| `nixos-aws`, `nixos-installer` | NixOS + disko | Cloud host and its installer variant | `nixos-anywhere --flake .#<target> root@<ip>` |

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
pve/                       Proxmox host snapshots, scripts, and dry-run sync support
deploy/, k8s/              Infrastructure definitions and manifests
```

The normal composition rule is: put reusable user configuration in
`users/felipe/home-modules/` or `system/`, and keep `hosts/<name>/` limited to
real host differences.

The Home Manager layering is a single chain, so a change lands on every host:

```text
users/felipe/home-modules/shell.nix   zsh, tmux, and the ~/.local/bin helpers
        ↑
system/home-terminal.nix              terminal layer: kitty, fzf, atuin, zoxide,
                                      direnv, neovim, ai-env, tmuxinator
        ↑                                   ↑
system/home.nix                       hosts/ubuntu-dev/home.nix
(graphical NixOS: hypr, dconf,        (Nix-on-Ubuntu)
 gnome-keyring, user services)
```

`hosts/mac/home.nix` imports `shell.nix` directly, since the darwin host does
not want the Linux terminal layer.

Shell helpers live in `system/scripts/` as ordinary executable files and are
linked into `~/.local/bin` with `mkOutOfStoreSymlink`. Do not inline new scripts
into Nix string literals: files on disk are shellcheck-able in CI, need no
`''${}` escaping, and can be edited without a rebuild. The two exceptions
(`tmux-save`, `tmux-restore`) are thin generated wrappers that only export the
tmux-resurrect store path before exec'ing the real script.

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

# Parse every module. Catches duplicate attributes in files that the target
# you happen to evaluate does not import.
find . -name '*.nix' -not -path './.git/*' -not -name private-hosts.nix \
  -exec nix-instantiate --parse {} \; >/dev/null

# Lint the repository scripts, including the tmux helpers. Discovery is by
# shebang: most scripts in system/scripts have no .sh suffix.
grep -rlIE '^#!.*/(env +)?(ba)?sh|^# shellcheck shell=' system/scripts pve \
  | xargs nix run nixpkgs#shellcheck -- -S error
```

CI runs all of the above plus a tmuxinator project check (`startup_window` must
name a window that exists) and evaluates every flake target.

A Home Manager build creates or refreshes the local `result` link; `.gitignore`
excludes it. Review `git diff --check` and `git status --short` before a
switch or commit.

## Editable configurations and ownership

`export/` and selected repository files are deliberately linked into `$HOME`
with `mkOutOfStoreSymlink`. This makes edits immediately visible but requires
that the checkout stays at `~/.dotfiles` on hosts that use these links.
Examples include tmuxinator projects, Neovim configuration, and AI harness
defaults.

Generated outputs, Python bytecode, package managers, and operating-system
metadata do not belong in the repository. Keep user data and application
caches out of this tree.

## Secrets and recovery

Do not add credentials, tokens, private keys, or authentication caches to this
repository. Use 1Password or another secret manager; local fallback files must
be ignored and permission-restricted. Review `.gitignore` and
[docs/publish-checklist.md](docs/publish-checklist.md) before sharing the
repository.

`system/private-hosts.nix` is git-crypt encrypted. Without the key it stays
ciphertext, which is not valid Nix, so the hosts importing it (`default-msi`,
`default-hp`, `mac`) cannot be evaluated. CI substitutes
`system/example.private-hosts.nix` for that reason; do the same locally if you
need to evaluate those targets without unlocking. That example must evaluate to
a string, matching how the real file is consumed.

Historical rescue material belongs in a local, permission-restricted archive
outside this repository. It is never active configuration and is excluded from
Git because rescue snapshots commonly contain generated payloads or
authentication caches. Never import rescue files into an active host without
comparing them against the currently managed modules.

For a failed Home Manager activation, select an earlier generation with
`home-manager generations` and activate that generation. For NixOS hosts, use
the boot menu or `sudo nixos-rebuild switch --rollback`.
