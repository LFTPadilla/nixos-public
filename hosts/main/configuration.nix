{
  config,
  lib,
  pkgs,
  inputs,
  hmStateVersion,
  ...
}: {
  imports = [
    ../../system/hardware-configuration.nix
    ../../system/desktops/gnome.nix
    ../../system/desktops/hyprland.nix
    ../../system/modules/kubernetes.nix
    ../../system/modules/work-launcher.nix
    ../../system/modules/semi-active-av.nix
    ../../system/applications/default.nix
  ];

  # Enable semi-active antivirus (ClamAV daemon + freshclam + on-access watcher + scheduled scans)
  # semi-active-av.enable = true;

  # Enable power-profiles-daemon for GUI power control
  services.power-profiles-daemon.enable = true;

  # Enhanced power management
  powerManagement.enable = true;

  # Disable conflicting services
  services.auto-cpufreq.enable = false;

  # Thermal and power management
  services.thermald.enable = true;
  services.upower.enable = true;
  services.acpid.enable = true;

  # System monitoring alternatives
  # Note: Using btop/htop for now as Netdata web interface has issues in NixOS
  # System monitoring alternatives
  # Note: Using btop/htop for now as Netdata web interface has issues in NixOS
  # services.netdata.enable = true;  # Disabled - web interface not working properly

  # Enhanced system logging
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    SystemMaxFileSize=50M
    SystemMaxFiles=10
    MaxRetentionSec=2week
    Compress=yes
    RateLimitInterval=30s
    RateLimitBurst=10000
  '';

  # Extended shutdown timeouts for graceful app closure
  # Prevents Chrome "restore tabs" by giving apps time to save state
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "300s";
    DefaultTimeoutStartSec = "120s";
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 30;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Kernel modules for hardware support
    kernelModules = [
      "uinput"
      "uhid"
      "intel_pstate"
      "cpufreq_conservative"
      "cpufreq_ondemand"
      "v4l2loopback"
    ];
    extraModulePackages = [config.boot.kernelPackages.v4l2loopback];

    # Hardware-specific optimizations
    extraModprobeConfig = ''
      options intel_pstate force_load=1
      options snd-hda-intel power_save=0
      # Disable MediaTek MT7925 (RZ717) power saving to prevent link flaps
      options mt7925e disable_aspm=1
      options pcie_aspm.policy=default
      # Bluetooth power management and HFP fixes
      options btusb enable_autosuspend=0
      options bluetooth disable_ertm=1
      options bluetooth disable_esco=0
      # v4l2loopback for OBS virtual camera
      options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    '';

    # Performance and compatibility
    kernelParams = [
      "quiet"
      "splash"
      "intel_pstate=active"
      "mitigations=auto"
    ];
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      # Enable automatic cleanup when disk space is low
      min-free = toString (100 * 1024 * 1024); # 100MB
      max-free = toString (1024 * 1024 * 1024); # 1GB
      # Performance optimizations
      max-jobs = "auto";
      cores = 0; # Use all available cores
      # Security and performance
      sandbox = true;
      # Reduce substituter load
      connect-timeout = 5;
      # Build isolation
      keep-outputs = true;
      keep-derivations = true;
    };
  };

  # Allow root-owned services (e.g. system.autoUpgrade) to read this user-owned flake repo.
  environment.etc."gitconfig".text = ''
    [safe]
      directory = /home/felipe/.dotfiles
  '';

  nixpkgs.config = {
    allowUnsupportedSystem = true;
    # allowUnfree comes from nixosDefaults in flake.nix. Note that with
    # allowUnfree = true the predicate below is inert; it only takes effect if
    # allowUnfree is turned off again.
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "1password-gui"
        "1password"
      ];
  };

  # Allow running prebuilt dynamically-linked binaries (e.g., npm CLIs)
  # This installs a stub dynamic linker and configures common runtime libs
  # so tools like `opencode` (from opencode-ai) work on NixOS.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc # libstdc++, libgcc_s
      zlib
      zstd
      openssl
      curl
    ];
  };

  networking = {
    hostName = "nixos";
    extraHosts = import ../../system/private-hosts.nix;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      # Prevent NetworkManager from fighting with other interfaces
      unmanaged = [
        "docker0"
        "br-*"
        "veth*"
        "tailscale0"
      ];
      wifi.powersave = false;
    };
    firewall = {
      enable = true;
      # Sunshine game streaming ports
      allowedTCPPorts = [
        47984
        47989
        47990
        48010 # Sunshine streaming
        5900 # VNC (when needed)
        2377
        7946 # Docker Swarm (if used)
        3131 # Development server
        6080 # noVNC web client
        9222 # Chrome debugging
        27124 # Steam Link
        53317 # LocalSend (HTTP/HTTPS API & transfer)
      ];
      allowedUDPPorts = [
        # Sunshine streaming (full recommended range for all modes/bitrates)
        47998
        47999
        48000
        48001
        48002
        48003
        48004
        48005
        48006
        48007
        48008
        48009
        48010
        # Other services
        7946
        4789 # Docker Swarm
        3131 # Development server
        41641 # Tailscale/WireGuard
        53317 # LocalSend (multicast discovery)
      ];
      # Trust Tailscale interface so services are reachable over the tailnet
      trustedInterfaces = ["tailscale0"];
      logRefusedConnections = true;
      logReversePathDrops = true;
      # Enhanced security rules
      extraCommands = ''
        # Rate limiting for SSH
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP

        # Drop invalid packets
        iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

        # Rate limit ICMP
        iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 2 -j ACCEPT
        iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
      '';
    };
  };

  # Enhanced Bluetooth configuration for better HFP/call support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        MultiProfile = "multiple";
        FastConnectable = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
        AutoConnect = true;
        # Improve HFP compatibility
        Class = "0x000100";
        DiscoverableTimeout = 0;
        # Enable experimental features for better compatibility
        Experimental = true;
      };
      Policy = {
        AutoEnable = true;
        ReconnectUUIDs = "00001108-0000-1000-8000-00805f9b34fb,0000110b-0000-1000-8000-00805f9b34fb,0000111e-0000-1000-8000-00805f9b34fb";
        ReconnectAttempts = 5;
        ReconnectIntervals = "1,2,4,8,16";
      };
    };
  };

  # Biometric authentication (disabled on MSI GS65)
  # Fingerprint reader is not present/used on this machine.
  # If you re-enable later, switch these back on.
  # services.fprintd.enable = true;
  # systemd.services.fprintd = {
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "simple";
  # };

  # Enhanced PAM configuration for fingerprint (disabled)
  # security.pam.services = {
  #   login.fprintAuth = lib.mkDefault true;
  #   gdm.fprintAuth = lib.mkDefault true;
  #   gdm-fingerprint.fprintAuth = lib.mkDefault true;
  #   sudo.fprintAuth = lib.mkDefault true;
  #   polkit-1.fprintAuth = lib.mkDefault true;
  # };

  # Additional security hardening
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    # Disable sudo password timeout
    sudo.execWheelOnly = true;
  };

  time.timeZone = "America/Bogota";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "altgr-intl";
      };
      serverFlagsSection = ''
        Option "BlankTime" "0"
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime" "0"
        Option "DontVTSwitch" "true"
        Option "DontZap" "true"
      '';
    };

    # System services
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # Enhanced Bluetooth audio configuration (WirePlumber 0.5+ API)
      wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-bluez-config.conf" ''
          monitor.bluez.properties = {
            bluez5.enable-sbc-xq = true
            bluez5.enable-msbc = true
            bluez5.enable-hw-volume = true
            bluez5.headset-roles = [ hsp_hs hsp_ag hfp_hf hfp_ag ]
            bluez5.hfp-offload-sco = false
          }
        '')
      ];
    };
    timesyncd.enable = true;
    openssh.enable = true;
    spice-vdagentd.enable = true;
  };

  # Enable I²C for DDC/CI (external monitor brightness control)
  hardware.i2c.enable = true;

  # Razer peripherals (Naga V2 HyperSpeed)
  hardware.openrazer = {
    enable = true;
    users = ["felipe"];
  };

  home-manager = {
    backupFileExtension = "hm-bak";
    extraSpecialArgs = {inherit inputs hmStateVersion;};
    users = {
      "felipe" = import ../../system/home.nix;
      "root" = {
        pkgs,
        hmStateVersion,
        ...
      }: {
        programs.home-manager.enable = true;
        home.stateVersion = hmStateVersion;
        programs.bash.enable = true;
        programs.bash.shellAliases = {
          ll = "ls -l --color=auto";
          la = "ls -A --color=auto";
          ".." = "cd ..";
        };
      };
    };
  };

  # Enhanced DNS configuration (resolved.conf(5) via settings.Resolve)
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      FallbackDNS = [
        "9.9.9.9"
        "149.112.112.112"
      ];
      MulticastDNS = "no";
      LLMNR = "no";
      ReadEtcHosts = "yes";
      Cache = "yes";
      CacheFromLocalhost = "no";
      DNSStubListener = "yes";
      ResolveUnicastSingleLabel = "no";
      DNSOverTLS = "opportunistic";
      CacheSize = "1000";
    };
  };

  # Prefer wired over Wi‑Fi for default route to prevent route flapping
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeShellScript "nm-route-metrics.sh" ''
        #!/usr/bin/env bash
        IFACE="$1"
        ACTION="$2"
        # Only adjust on connection up
        [[ "$ACTION" == "up" ]] || exit 0

        # Find connection UUID for this device
        UUID=$(nmcli -g GENERAL.CONNECTION device show "$IFACE" 2>/dev/null | head -n1)
        [[ -n "$UUID" ]] || UUID="$CONNECTION_UUID"
        [[ -n "$UUID" ]] || exit 0

        TYPE=$(nmcli -g connection.type connection show "$UUID" 2>/dev/null)
        case "$TYPE" in
          ethernet)
            nmcli connection modify "$UUID" ipv4.route-metric 100 ipv6.route-metric 100 || true
            ;;
          wifi)
            nmcli connection modify "$UUID" ipv4.route-metric 600 ipv6.route-metric 600 || true
            ;;
        esac
      '';
    }
  ];

  # Disable problematic Nextcloud GOA integration
  services.gnome.gnome-online-accounts.enable = lib.mkForce false;

  users.users.felipe = {
    ignoreShellProgramCheck = true;
    isNormalUser = true;
    description = "Felipe";
    extraGroups = [
      "video"
      "libvirtd"
      "kvm"
      "input"
      "i2c"
      "render"
      "networkmanager"
      "wheel"
      "docker"
      "dialout"
      "uucp"
      "fuse"
      "vboxusers"
      "plugdev"
    ];
    shell = pkgs.zsh;
    packages = [];
  };

  # Shell setup is now managed via Home Manager for felipe only

  environment.systemPackages = let
    packages = import ../../system/packages {inherit pkgs inputs;};
  in
    packages.systemPackages;

  # Allow felipe to control power profiles without password
  security.sudo.extraRules = [
    {
      users = ["felipe"];
      commands = [
        {
          command = "/run/current-system/sw/bin/powerprofilesctl";
          options = ["NOPASSWD"];
        }
        {
          command = "/home/felipe/.dotfiles/users/felipe/homeassistant/eco-mode.sh";
          options = ["NOPASSWD"];
        }
        {
          command = "/home/felipe/.dotfiles/users/felipe/homeassistant/performance-mode.sh";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Enable Tailscale with conservative DNS settings to avoid conflicts
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraUpFlags = ["--accept-dns=false"];
  };
  programs.sunshine.enable = true;

  kubernetes-tools = {
    enable = true;
    kubeconfigPath = "/home/felipe/.kube/k8s-cluster.dev.dman.cloud.yaml";
  };

  # Enable work application launcher
  services.work-launcher = {
    enable = true;
    launchDelay = 1;
  };

  # systemd.services.hacompanion = {
  #   description = "hacompanion daemon";
  #   wantedBy = ["multi-user.target"];
  #   after = ["network.target" "graphical-session.target"];
  #   wants = ["graphical-session.target"];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.hacompanion}/bin/hacompanion -config=/home/felipe/.dotfiles/users/felipe/homeassistant/hacompanion.toml";
  #     Restart = "on-failure";
  #     RestartSec = "10s";
  #     User = "felipe";
  #     Group = "users";
  #     Environment = [
  #       "PATH=/run/wrappers/bin:/home/felipe/.nix-profile/bin:/etc/profiles/per-user/felipe/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
  #       "XDG_RUNTIME_DIR=/run/user/1000"
  #       "PULSE_RUNTIME_PATH=/run/user/1000/pulse"
  #     ];
  #   };
  # };
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0666", GROUP="dialout"

    # Sunshine udev rules for virtual input devices
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
    KERNEL=="uhid", MODE="0660", GROUP="input"

    # NexiGo N60 webcam: reset digital zoom, pan, tilt to defaults on connect
    ACTION=="add", SUBSYSTEM=="video4linux", ATTRS{idVendor}=="3443", ATTRS{idProduct}=="60bb", RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl --device=$devnode --set-ctrl=zoom_absolute=10,pan_absolute=0,tilt_absolute=0"
  '';

  environment.sessionVariables = {
    TERMINAL = "kitty";
    DEFAULT_TERMINAL = "kitty";
    BROWSER = "brave"; # Set Brave as default browser
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["felipe"];
  };

  # Enable bandwhich for network monitoring
  programs.bandwhich.enable = true;

  # Enable Steam for gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        # ovmf.enable = true;
        # ovmf.packages = [pkgs.OVMFFull.fd];
      };
    };
    # Enable VirtualBox host drivers and tools
    # virtualbox.host = {
    #   enable = true;
    #   enableExtensionPack = true;
    # };
    spiceUSBRedirection.enable = true;
    docker = {
      enable = true;
      liveRestore = false;
      # autoPrune = {
      #   enable = true;
      #   dates = "weekly";
      # };
      # daemon.settings = {
      #   data-root = "/home/felipe/docker-data";
      #   log-driver = "json-file";
      #   log-opts = {
      #     max-size = "10m";
      #     max-file = "3";
      #   };
      # };
    };
  };

  programs = {
    fuse.userAllowOther = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    firefox.enable = true;
  };

  # programs.sway = {
  #   enable = true;
  #   wrapperFeatures.gtk = true; # For theming gtk apps
  # };

  # Simplified font configuration for better performance
  # fonts = {
  #   fontconfig = {
  #     enable = true;
  #     defaultFonts = {
  #       serif = ["Liberation Serif" "DejaVu Serif"];
  #       sansSerif = ["Liberation Sans" "DejaVu Sans"];
  #       monospace = ["JetBrainsMono Nerd Font" "Liberation Mono"];
  #     };
  #   };
  #   packages = with pkgs; [
  #     noto-fonts
  #     noto-fonts-emoji
  #     liberation_ttf
  #     jetbrains-mono
  #     fira-code
  #   ];
  # };

  # Storage optimizations
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # Enable firmware updates
  services.fwupd.enable = true;
  # Make fwupd-refresh wait for network to avoid metadata fetch failures at boot
  systemd.services.fwupd-refresh = {
    wants = ["network-online.target"];
    after = ["network-online.target"];
  };

  # services.tlp.enable = true;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
  # Automatic cleanup
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d"; # Keep more history for safety
  };

  # Auto-optimize store weekly
  nix.optimise = {
    automatic = true;
    dates = ["weekly"];
  };

  fonts = {
    packages = with pkgs; [
      jetbrains-mono
      inter
      noto-fonts
      noto-fonts-color-emoji
      liberation_ttf
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "JetBrains Mono"
        ];
        emoji = ["Noto Color Emoji"];
      };
    };
  };

  # Optimized kernel parameters
  boot.kernel.sysctl = {
    # Memory management (SSD optimized)
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
    "vm.vfs_cache_pressure" = 50;
    # Network performance
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    # File system performance
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    # Security hardening
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };

  system.stateVersion = "25.05";

  # Desktop selection: Hyprland only
  desktop.gnome.enable = false;
  desktop.hyprland.enable = true;

  # Use greetd to launch Hyprland directly instead of GDM
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "felipe";
      };
    };
  };
}
