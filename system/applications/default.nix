{lib, ...}: {
  # The commented-out dunst/fonts/gtk/i3/picom/polybar/xorg imports were removed:
  # none of those files exist, so they could never be uncommented as-is.
  imports = [
    ./waybar.nix
    ./rofi.nix
    ./swaync.nix
    ./sunshine.nix
  ];

  options = {
    # Primary username used by application modules that configure Home Manager
    user = lib.mkOption {
      type = lib.types.str;
      default = "felipe";
      description = "Primary user for Home Manager application configurations.";
    };

    launcherCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command to use for launching";
    };
    systemdSearch = lib.mkOption {
      type = lib.types.str;
      description = "Command to use for interacting with systemd";
    };
    altTabCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command to use for choosing windows";
    };
    audioSwitchCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command to use for switching audio sink";
    };
    brightnessCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command to use for adjusting brightness";
    };
    calculatorCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command to use for quick calculations";
    };
    powerCommand = lib.mkOption {
      type = lib.types.str;
      description = "Command to use for power options menu";
    };
    terminal = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Path to executable for terminal emulator program.";
      default = null;
    };
  };
}
