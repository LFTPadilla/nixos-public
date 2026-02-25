{pkgs}:
# System-wide packages that require root privileges or system-level integration
with pkgs; [
  # Performance monitoring and graphics tools
  intel-gpu-tools # Tools for monitoring and debugging Intel graphics
  mesa-demos # OpenGL testing utilities like glxinfo and glxgears
  vulkan-tools # Vulkan support and testing utilities
  powertop # Power consumption and management diagnosis
  # nvtop temporarily removed to avoid pulling CUDA hooks
  libva-utils # Tools for VA-API (video acceleration)

  # Enhanced system monitoring
  lm_sensors # Hardware temperature monitoring
  smartmontools # Disk health monitoring
  iotop # I/O monitoring
  nethogs # Network usage per process
  bandwhich # Network utilization by process

  # System Utilities
  nitch # similar to neofetch
  pciutils
  alsa-utils
  ddcutil # Control external monitor via DDC/CI
  brightnessctl # Control laptop panel backlight
  wget
  lf
  gparted
  tmux
  openssh
  openssl
  putty # PuTTY CLI tools (plink, pscp, puttygen)
  usbutils
  dig # nslookup
  nmap
  rofi
  xdotool
  moonlight-qt
  sunshine
  gh
  speedtest-cli # Internet speed testing tool
  zbar # QR/barcode scanner (zbarimg, zbarcam)
  s3fs # S3 bucket mount tool

  # Enhanced command-line tools for keyboard workflow
  procs # Modern ps replacement
  dust # Modern du replacement
  duf # Modern df replacement
  ripgrep # Modern grep replacement
  fd # Modern find replacement
  eza # Modern ls replacement (already in use)
  bat # Modern cat replacement
  btop # Modern htop replacement
  zoxide # Smart cd replacement

  # AppImage support
  appimage-run # Run AppImages on NixOS

  # Virtualization & Remote Access
  # rustdesk
  virt-manager
  virt-viewer
  spice
  spice-gtk
  spice-protocol
  virtio-win
  win-spice

  # AI tooling
  # coderabbitcli

  # Cloud & DevOps
  awscli2

  # Media & Office
  vlc
  libreoffice

  # Streaming & Recording
  obs-studio # OBS Studio with virtual camera support
  v4l-utils # Video4Linux utilities for virtual camera

  # ClamAV (commented out but available)
  # clamav

  # Desktop items
  (makeDesktopItem {
    name = "kitty";
    desktopName = "Kitty Terminal";
    exec = "${pkgs.kitty}/bin/kitty";
    icon = "kitty";
    terminal = false;
    type = "Application";
    categories = ["System" "TerminalEmulator"];
    mimeTypes = ["application/x-terminal-emulator"];
  })
]
