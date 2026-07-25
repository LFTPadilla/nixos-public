{pkgs, ...}: {
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
    neofetch
    nil
    nixd
    nodejs_22
    python3
    python3Packages.pip
    satty
    starship
    tmux
    tmuxinator
    uv
    xclip
    yazi
    zoxide
    zsh
  ];
}
