{
  modulesPath,
  lib,
  pkgs,
  ...
} @ args: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  disko.devices.disk.disk1.device = "/dev/nvme0n1";
  services.openssh.enable = true;

  # Hostname
  networking.hostName = "nixos-proxmox";

  # Minimal firewall + Tailscale settings
  # networking.firewall = {
  #   enable = true;
  #   allowedUDPPorts = [ 41641 ]; # Tailscale/WireGuard
  #   trustedInterfaces = [ "tailscale0" ];
  # };

  # services.tailscale = {
  #   enable = true;
  #   # Keep DNS stable (MagicDNS disabled). Remove to enable MagicDNS later.
  #   extraUpFlags = [ "--accept-dns=false" ];
  # };

  # # AWS Systems Manager (SSM) Agent for Session Manager access
  # services.amazon-ssm-agent.enable = true;

  # Enable Docker service
  # virtualisation.docker.enable = true;

  # environment.systemPackages = map lib.lowPrio [
  #   pkgs.curl
  #   pkgs.gitMinimal
  #   pkgs.docker
  # ];

  environment.systemPackages = with pkgs; [
    # Remove GUI packages not needed for remote access
    # Keep development tools
    git
    curl
    # neovim
    # tmux
    # htop
    # wget
    # btop

    # Shell alias dependencies (from system/modules/shell.nix)
    # eza       # ls replacement
    # bat       # cat replacement
    # ripgrep   # grep replacement (rg)
    # fd        # find replacement
    # zoxide    # smart cd (z)
    # procs     # ps replacement
    # dust      # du replacement
    # duf       # df replacement
    # yazi      # terminal file manager (y)
    # xclip     # clipboard for pbcopy/pbpaste aliases

    # # Dev tools
    # awscli2
    # docker
  ];

  # Keep root on default shell (bash); felipe explicitly uses zsh below

  environment.sessionVariables = {
    TERMINAL = "kitty";
    DEFAULT_TERMINAL = "kitty";
    GDK_BACKEND = "x11";
    BROWSER = "brave"; # Set Brave as default browser
  };

  # Shell setup for felipe is managed via Home Manager

  users.users.felipe = {
    ignoreShellProgramCheck = true;
    isNormalUser = true;
    description = "Felipe";
    extraGroups = ["video" "networkmanager" "wheel" "docker" "fuse"];
    shell = pkgs.zsh;
    # Allow SSH login with the same keys as root
    openssh.authorizedKeys.keys = args.extraPublicKeys or [];
    packages = [];
  };

  # Home Manager (enable for felipe, include Atuin with inline UI)
  # home-manager = {
  #   useGlobalPkgs = true;
  #   useUserPackages = true;
  #   users.felipe = { pkgs, ... }: {
  #     programs.home-manager.enable = true;
  #     home.stateVersion = "24.05"; # match this host's system.stateVersion

  #     programs.atuin = {
  #       enable = true;
  #       enableZshIntegration = true;
  #       settings = {
  #         auto_sync = true;
  #         sync_frequency = "5m";
  #         search_mode = "prefix";
  #         style = "compact";
  #         inline_height = 12;
  #         inline_height_shell_up_key_binding = 12;
  #       };
  #     };
  #   };
  # };

  users.users.root.openssh.authorizedKeys.keys = args.extraPublicKeys or [];

  system.stateVersion = "24.05";

  # Allow FUSE mounts with -o allow_other
  programs.fuse.userAllowOther = true;
}
