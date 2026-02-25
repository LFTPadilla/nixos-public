{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.desktop.gnome;
in {
  options.desktop.gnome.enable = lib.mkEnableOption "GNOME desktop environment";

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
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

      # Use new option names for NixOS 26.05+
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;

      # GNOME online accounts can cause issues; keep disabled by default
      gnome.gnome-online-accounts.enable = lib.mkForce false;
    };
  };
}
