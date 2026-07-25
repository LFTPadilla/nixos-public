{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.desktop.hyprland;
in {
  options.desktop.hyprland.enable = lib.mkEnableOption "Hyprland Wayland compositor";

  config = lib.mkIf cfg.enable {
    # Enable Hyprland and Xwayland
    programs.hyprland.enable = true;
    services.xserver.enable = true;

    # Desktop portals for Wayland (used by screenshots, file pickers, etc.)
    xdg.portal = {
      enable = true;
      wlr.enable = false;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = ["hyprland" "gtk"];
    };

    # Basic Wayland desktop tooling
    environment.systemPackages = with pkgs; [
      hyprland
      waybar
      swaybg
      swaynotificationcenter
      awww # renamed upstream from swww
      kitty
      wl-clipboard
      grim
      slurp
      satty
    ];
  };
}
