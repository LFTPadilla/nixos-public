{
  pkgs,
  inputs,
  lib,
  ...
} @ args: let
  packages = import ../../system/packages {inherit pkgs inputs;};
  hardwareConfig = ./. + "/hardware-configuration.nix";
  sshKeys =
    [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOxue2KK9duORxcXOsvguCJ47NuT/lY6ZhSG+RroLa8isH+z+inXQfS/AGoUAPKQ2DSp4qNIMxcH4RoXTOZZFeYSqAnVcjbSQbq8aK5m0g2U41icOeGo/B5lSiSi2CWXEyombcA/1rU8coq0+XGhsemWpU0oaYIzH1ZvVMiRGc5uBhGUbP06jslWAmilyZc0zCRSBzKyLmUqKHibqrUBXvL4UN3MmJ10IZdjCoTXtUqc9KB52HDifEe3pnGlB4OkpscRmeAPs6mGi8qUDmL0DlKWjAIdZK0xTpd+dgHIMDg6iMJJUjE1lDZUM5zggj7g8RAN2sPQQS5gDM0SvOpY/N"
    ]
    ++ (args.extraPublicKeys or []);
in {
  # Automatically import host-specific hardware configuration when present.
  imports =
    lib.optional (builtins.pathExists hardwareConfig) hardwareConfig
    ++ [
      ../../system/modules/kubernetes.nix
      ../../system/desktops/gnome.nix
    ];

  # Enable GNOME desktop environment
  desktop.gnome.enable = true;

  networking = {
    hostName = "gmk";
    networkmanager.enable = true;
  };

  time.timeZone = "America/Bogota";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "es_CO.UTF-8";
      LC_IDENTIFICATION = "es_CO.UTF-8";
      LC_MEASUREMENT = "es_CO.UTF-8";
      LC_MONETARY = "es_CO.UTF-8";
      LC_NAME = "es_CO.UTF-8";
      LC_NUMERIC = "es_CO.UTF-8";
      LC_PAPER = "es_CO.UTF-8";
      LC_TELEPHONE = "es_CO.UTF-8";
      LC_TIME = "es_CO.UTF-8";
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Graphics support for Intel Iris Xe (12th gen Alder Lake)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # VAAPI driver for newer Intel GPUs (Broadwell+)
      intel-compute-runtime # OpenCL support
      intel-vaapi-driver # Older VAAPI driver (fallback)
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;

  # Enable hardware video acceleration
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
  };

  # Force Intel i915 driver
  boot.kernelParams = ["i915.force_probe=*"];

  # Laptop power management
  services.power-profiles-daemon.enable = true;

  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.luis = {
    isNormalUser = true;
    description = "Luis";
    ignoreShellProgramCheck = true;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = [];
    openssh.authorizedKeys.keys = sshKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  environment.systemPackages = packages.systemPackages;

  nixpkgs.config.allowUnfree = true;

  # Sound support
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  virtualisation.docker = {
    enable = true;
    liveRestore = false;
  };

  # Ensure Docker network for Immich exists
  systemd.services.docker-network-homeserver_default = {
    description = "Create Docker network homeserver_default";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.docker}/bin/docker network create homeserver_default || true";
    };
  };

  # Automatically start Immich docker-compose stack on boot
  systemd.services.immich = {
    description = "Immich docker-compose stack";
    after = [
      "docker.service"
      "docker-network-homeserver_default.service"
      "network-online.target"
    ];
    requires = [
      "docker.service"
      "docker-network-homeserver_default.service"
    ];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/home/luis/immich/config";
      User = "luis";
      Group = "docker";
      ExecStart = "${pkgs.docker}/bin/docker compose -f compose.immich.yml up -d";
      ExecStop = "${pkgs.docker}/bin/docker compose -f compose.immich.yml down";
    };
  };

  # Session variables needed by the CLI helpers and shell modules
  environment.sessionVariables = {
    TERMINAL = "kitty";
    DEFAULT_TERMINAL = "kitty";
    GDK_BACKEND = "x11";
    BROWSER = "brave";
  };

  kubernetes-tools = {
    enable = true;
    kubeconfigPath = "/home/luis/.kube/k8s-cluster.dev.dman.cloud.yaml";
  };

  programs.fuse.userAllowOther = true;

  system.stateVersion = "25.05";
}
