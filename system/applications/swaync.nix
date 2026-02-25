{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home-manager.users.${config.user} = {
      xdg.configFile."swaync/config.json".text = builtins.readFile ./swaync/config.json;
      xdg.configFile."swaync/style.css".text = builtins.readFile ./swaync/style.css;
    };
  };
}
