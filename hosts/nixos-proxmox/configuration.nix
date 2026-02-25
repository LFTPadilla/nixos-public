{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan for this Proxmox VM.
    ../../system/nixos-proxmox-hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Bogota";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
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

  # Basic desktop (can be extended later)
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Sound with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Sunshine game streaming server
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # User
  users.users.felipe = {
    isNormalUser = true;
    description = "felipe";
    # Allow desktop, Docker, and virtual input (Sunshine) access
    extraGroups = ["networkmanager" "wheel" "docker" "input"];
    packages = with pkgs; [];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic packages (reuse shared system package set to avoid duplication)
  environment.systemPackages = let
    packages = import ../../system/packages {inherit pkgs inputs;};
  in
    packages.systemPackages;

  # Browsers and developer tools are included via systemPackages; enable Firefox
  programs.firefox.enable = true;

  # Docker service
  virtualisation.docker = {
    enable = true;
    liveRestore = false;
  };

  # Relaxed udev permissions so Sunshine (running as felipe) can inject input
  services.udev.extraRules = ''
    # Sunshine udev rules for virtual input devices
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
    KERNEL=="uhid", MODE="0660", GROUP="input"
  '';

  # Home Manager with your full home + shell modules
  home-manager = {
    backupFileExtension = "hm-bak";
    extraSpecialArgs = {inherit inputs;};
    users = {
      "felipe" = import ../../system/home-terminal.nix;
      "root" = {pkgs, ...}: {
        programs.home-manager.enable = true;
        home.stateVersion = "24.05";
        programs.bash.enable = true;
        programs.bash.shellAliases = {
          ll = "ls -l --color=auto";
          la = "ls -A --color=auto";
          ".." = "cd ..";
        };
      };
    };
  };

  system.stateVersion = "25.05";
}
