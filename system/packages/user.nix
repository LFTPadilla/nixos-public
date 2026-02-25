{pkgs}:
# User-specific packages managed by Home Manager
with pkgs; [
  # Terminal utilities
  neofetch
  nnn

  # Archives
  zip
  xz
  unzip
  p7zip

  # Modern CLI utilities
  eza # A modern replacement for 'ls'
  fzf # A command-line fuzzy finder
  kitty
  kitty.terminfo
  yazi # File manager
  trash-cli # Safer deletions via trash
  xclip # for clipboard support
  less # for scrollback pager
  zoxide # Smart cd replacement

  # Cursor theme (Wayland/X11)
  bibata-cursors

  # System tools
  sysstat
  lm_sensors # for `sensors` command
  ethtool
  xprintidle # for idle time detection

  # Communication
  teams-for-linux

  # Productivity tracking
  activitywatch

  # GNOME Extensions
  gnome-shell-extensions
  gnomeExtensions.night-theme-switcher
  gnomeExtensions.emoji-copy
  gnomeExtensions.brightness-control-using-ddcutil
  gnomeExtensions.status-area-horizontal-spacing
  gnomeExtensions.clipboard-indicator
  gnomeExtensions.bluetooth-battery-meter
  gnomeExtensions.extensions-glass-grid
  gnomeExtensions.bing-wallpaper-changer
  gnomeExtensions.alphabetical-app-grid
  gnomeExtensions.media-controls
  gnomeExtensions.runcat
  gnomeExtensions.quick-settings-audio-panel
  gnomeExtensions.allow-locked-remote-desktop
  gnomeExtensions.easy-docker-containers
  gnomeExtensions.nothing-to-say
  gnomeExtensions.tiling-assistant
  gnomeExtensions.dash-to-panel
  gnomeExtensions.transparent-window-moving
  gnomeExtensions.dim-background-windows
  gnomeExtensions.compiz-windows-effect
  gnomeExtensions.do-not-disturb-while-screen-sharing-or-recording
  gnomeExtensions.steal-my-focus-window
  # gnomeExtensions.vitals
  # gnomeExtensions.extension-list
  # gnomeExtensions.places-status-indicator # conflict with gnome-shell-extensions
  # gnomeExtensions.transmission # do not exist on nixos pkgs
  # gnomeExtensions.sound-percentage # do not exist on nixos pkgs

  # Rofi desktop launcher
  (makeDesktopItem {
    name = "rofi-launcher";
    desktopName = "Rofi Application Launcher";
    exec = "/home/felipe/.dotfiles/system/applications/rofi/rofi-wrapper.sh -show drun";
    icon = "rofi";
    comment = "Application launcher with search";
    genericName = "Application Launcher";
    categories = ["Utility" "System"];
  })

  # Create a simple launcher command for Rofi
  (pkgs.writeShellScriptBin "rofi-launcher" ''
    #!/bin/sh
    exec "$HOME/.dotfiles/system/applications/rofi/rofi-wrapper.sh" -show drun
  '')

  # Commented out packages for reference
  # inputs.zen-browser.packages."${system}".twilight
  # xa
  # bat
  # tokei
  # xsv
  # fd
  # tmux
  # jq
  # git-crypt
  # neovim
]
