{
  config,
  pkgs,
  lib,
  ...
}: let
  rofi = config.home-manager.users.${config.user}.programs.rofi.finalPackage;
  # Try to find rofi-file-browser-extended across nixpkgs variants
  hasFbe =
    (pkgs ? rofi-file-browser-extended)
    || ((pkgs ? rofiPlugins) && ((pkgs.rofiPlugins ? file-browser-extended) || (pkgs.rofiPlugins ? file-browser)));
  fbePkg =
    if pkgs ? rofi-file-browser-extended
    then pkgs.rofi-file-browser-extended
    else if (pkgs ? rofiPlugins) && (pkgs.rofiPlugins ? file-browser-extended)
    then pkgs.rofiPlugins.file-browser-extended
    else if (pkgs ? rofiPlugins) && (pkgs.rofiPlugins ? file-browser)
    then pkgs.rofiPlugins.file-browser
    else null;
in {
  imports = [
    ./rofi/power.nix
    ./rofi/brightness.nix
  ];

  config = lib.mkIf pkgs.stdenv.isLinux {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        jq # Required for rofi-systemd
      ];

      programs.rofi = {
        enable = true;
        cycle = true;
        location = "center";
        terminal = lib.mkIf (config.terminal != null) config.terminal;
        plugins =
          [
            pkgs.rofi-calc
            pkgs.rofi-emoji
            pkgs.rofi-systemd
          ]
          ++ lib.optional (fbePkg != null) fbePkg;
        extraConfig = {
          show-icons = true;
          kb-cancel = "Escape";
          modi = lib.concatStringsSep "," (
            ["drun" "window" "run" "ssh" "emoji" "calc"]
            ++ lib.optionals (fbePkg != null) ["filebrowser"]
          );
          sort = true;
        };
      };

      home.file.".local/share/rofi/themes" = {
        recursive = true;
        source = ./rofi/themes;
      };
    };

    launcherCommand = ''${rofi}/bin/rofi -modi drun -show drun -theme-str '@import "launcher.rasi"' '';
    systemdSearch = "${pkgs.rofi-systemd}/bin/rofi-systemd";
    altTabCommand = "${rofi}/bin/rofi -show window -modi window";
    calculatorCommand = "${rofi}/bin/rofi -modi calc -show calc";
    audioSwitchCommand = "${
      (pkgs.writeShellApplication {
        name = "switch-audio";
        runtimeInputs = [
          pkgs.ponymix
          rofi
        ];
        text = builtins.readFile ./rofi/pulse-sink.sh;
      })
    }/bin/switch-audio";
  };
}
