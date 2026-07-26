{pkgs, ...}: let
  # nixpkgs at the current lock still packages tmuxinator 3.3.7, whose tmux
  # version allow-list stops at 3.6a. 3.4.1 adds support through tmux 3.7b.
  tmuxinator_3_4_1 = pkgs.tmuxinator.overrideAttrs (_: rec {
    version = "3.4.1";
    name = "tmuxinator-${version}";
    src = pkgs.fetchurl {
      url = "https://rubygems.org/downloads/tmuxinator-${version}.gem";
      hash = "sha256-2BZgu3vybhpoScScq42yr80DYI343vqlQVQv2AOG48I=";
    };
    postInstall = ''
      installShellCompletion $GEM_HOME/gems/tmuxinator-${version}/completion/tmuxinator.{bash,zsh,fish}
    '';
  });
in {
  imports = [./base-cli.nix];

  home.packages = with pkgs; [
    aider-chat
    alejandra
    atuin
    curl
    direnv
    fzf
    gcc
    gh
    git
    # 1Password CLI is provided by the official .deb installed by the GUI
    # package (1password). The Nix _1password-cli lacks the desktop-app
    # integration helper, which breaks `op vault list` etc. Do not re-add
    # without verifying the integration still fails. 2026-07-13.
    gnumake
    go
    less
    lua-language-server
    fastfetch
    nil
    nixd
    nodejs_22
    python3
    python3Packages.pip
    satty
    starship
    tmux
    tmuxinator_3_4_1
    uv
    xclip
    yazi
    zoxide
    zsh
  ];
}
