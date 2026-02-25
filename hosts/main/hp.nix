{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../system/hardware-configuration.nix
  ];

  # Biometric authentication (HP ProBook fingerprint sensor)
  services.fprintd.enable = true;
  systemd.services.fprintd = {
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "simple";
  };

  # Enhanced PAM configuration for fingerprint
  security.pam.services = {
    login.fprintAuth = lib.mkDefault true;
    gdm.fprintAuth = lib.mkDefault true;
    gdm-fingerprint.fprintAuth = lib.mkDefault true;
    sudo.fprintAuth = lib.mkDefault true;
    polkit-1.fprintAuth = lib.mkDefault true;
  };

  # Safe automatic system updates (flake-aware) for the HP profile
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    flake = "/home/felipe/.dotfiles#default-hp";
    flags = [
      "--update-input"
      "nixpkgs"
      "--no-write-lock-file"
      "-L"
    ];
    dates = "09:00";
    randomizedDelaySec = "45min";
  };
}
