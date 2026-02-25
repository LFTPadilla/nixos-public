{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.sunshine;
in {
  options.programs.sunshine = with lib; {
    enable = mkEnableOption "sunshine";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 47984;
        to = 48010;
      }
    ];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48010;
      }
    ];
    security.wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${pkgs.sunshine}/bin/sunshine";
    };
    systemd.user.services.sunshine = {
      description = "Sunshine self-hosted game stream host for Moonlight";
      after = ["pipewire.service" "pipewire-pulse.service" "graphical-session.target"];
      wants = ["pipewire.service" "pipewire-pulse.service"];
      partOf = ["graphical-session.target"];
      wantedBy = ["default.target"];
      startLimitBurst = 5;
      startLimitIntervalSec = 500;
      environment = {
        XDG_RUNTIME_DIR = "%t";
        PULSE_RUNTIME_PATH = "%t/pulse";
        PULSE_SERVER = "unix:%t/pulse/native";
        PIPEWIRE_RUNTIME_DIR = "%t/pipewire";
        PIPEWIRE_REMOTE = "pipewire-0";
      };
      serviceConfig = {
        ExecStart = "${config.security.wrapperDir}/sunshine";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
