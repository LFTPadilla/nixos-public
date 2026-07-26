{pkgs, ...}: {
  home.packages = with pkgs; [
    bat
    btop
    duf
    eza
    fd
    jq
    k9s
    lazygit
    ranger
    ripgrep
    tree
    unzip
    wget
    xdg-utils
  ];
}
