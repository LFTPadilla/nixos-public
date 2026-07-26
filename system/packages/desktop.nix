{
  pkgs,
  inputs,
}:
# Desktop applications and user-facing software
(with pkgs; [
  # Web Browsers
  brave
  ungoogled-chromium
  google-chrome
  qutebrowser # Keyboard-driven web browser
  # librewolf
  # opera
  # firefox-devedition
  vivaldi

  # Development Tools (User-facing IDEs)
  vscode
  dbeaver-bin

  code-cursor
  warp-terminal
  # gitkraken

  # Communication & Productivity
  thunderbird
  obsidian
  bitwarden-desktop
  bitwarden-cli
  localsend
  blueman
  # tailscale  # removed per request
  # vesktop # Discord client # lost session frecuently
  # slack
  zoom-us
  telegram-desktop
  # super-productivity
  # webcord
  # betterdiscordctl
  # legcord

  # Media & Graphics
  # obs-studio # temporarily removed to avoid GPU-related hooks
  gimp
  davinci-resolve # removed to avoid pulling CUDA compat
  spotify
  qbittorrent

  # Gaming
  heroic # Epic Games, GOG, and Amazon Games launcher

  flameshot
  mission-center

  # File Management & Sync
  filezilla
  nextcloud-client
  kdePackages.dolphin

  # Fonts
  jetbrains-mono
  fira-code
  cascadia-code
  ibm-plex

  # Remote Access & Imaging
  realvnc-vnc-viewer
  rpi-imager

  # AI & Machine Learning
  # lmstudio # removed to avoid CUDA-related hooks
  # jan # removed to avoid CUDA-related hooks
  # ffmpeg # temporarily removed to avoid GPU-related hooks

  # Miscellaneous
  hacompanion

  media-downloader
  # obs-studio # temporarily removed to avoid GPU-related hooks
  pavucontrol
  soundwireserver
  video-trimmer # vlc: packages/system.nix

  ## Utility
  dconf-editor
  ddcui # GUI for controlling monitor brightness via DDC/CI
  zenity
  wdisplays # Wayland display layout GUI (mirror/extend quickly)

  ## Level editor
  # ldtk
  # tiled

  gdm
  gnome-browser-connector
  gnome-control-center
  gnome-disk-utility
  gnome-shell-extensions
  gnome-system-monitor
  gnome-text-editor
  gnome-tweaks
  gnome-sound-recorder
  nautilus
  polychromatic
])
++ [
  # Removed claude-desktop-linux-flake: unmaintained against current nixpkgs
  # (calls pkgs.nodePackages, removed 2026-03) and pulls EOL Electron 39.

  # Zen Browser
  # inputs.zen-browser.packages.${pkgs.system}.default
]
