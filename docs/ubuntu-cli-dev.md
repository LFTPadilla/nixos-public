# Ubuntu CLI Dev Host

This target is for an Ubuntu machine where you want Nix-managed CLI tooling
only, without switching the whole OS to NixOS. `ubuntu-dev` is the flake target
name, not a hostname requirement: the current machine's hostname is `ubuntu`.

It installs and configures:

- `zsh` with autosuggestions, syntax highlighting, aliases, and Starship
- `tmux` with the shared repo config and plugins
- `atuin`, `fzf`, `zoxide`, `direnv`, `git`, `gh`
- `neovim` wired to `system/nvim`
- development packages such as `nodejs_22`, `python3`, `go`, `uv`, `gcc`, `alejandra`, `nil`, `nixd`

## Bootstrap

Install Nix on Ubuntu:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Open a new shell, then install Home Manager from this flake:

```bash
git clone https://github.com/LFTPadilla/nixos-public.git ~/.dotfiles
cd ~/.dotfiles
nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev
```

## Post-install

Set `zsh` as the login shell:

```bash
command -v zsh
chsh -s "$(command -v zsh)"
```

If you use Atuin sync, authenticate once:

```bash
atuin login -u <your-user>
atuin sync
```

If you want GitHub HTTPS credential support through `gh`:

```bash
gh auth login
```

## Validate, update, and activate

```bash
cd ~/.dotfiles

# Keep the checkout deterministic; do not create a merge commit during routine updates.
git pull --ff-only

# Build first. This evaluates the Home Manager target without activating it.
nix run nixpkgs#home-manager -- build --flake .#ubuntu-dev

# Activate only after the build succeeds.
nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev
```

The repository helper, `bash system/scripts/rebuild`, makes the same
platform-specific switch. It no longer formats the checkout implicitly;
formatting is opt-in with `DOTFILES_FORMAT=1`.
