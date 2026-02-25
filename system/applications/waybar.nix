{
  config,
  lib,
  pkgs,
  ...
}: let
  powerProfileMenu = pkgs.writeShellScript "waybar-power-profile-menu" ''
    exec "$HOME/.dotfiles/system/applications/rofi/system-actions.sh" "🔋 Power Settings"
  '';

  powerProfileStatus = pkgs.writeShellScript "waybar-power-profile-status" ''
    set -euo pipefail

    if ! command -v powerprofilesctl >/dev/null 2>&1; then
      printf '{"text":"","tooltip":"powerprofilesctl not available"}\n'
      exit 0
    fi

    current=$(powerprofilesctl get 2>/dev/null | tr -d '[:space:]')

    icon=""
    case "$current" in
      performance) icon="" ;;
      power-saver) icon="" ;;
    esac

    printf '{"text":"%s %s","tooltip":"Power profile: %s"}\n' "$icon" "$current" "$current"
  '';

  systemActionsNetwork = pkgs.writeShellScript "waybar-network-settings" ''
    exec "$HOME/.dotfiles/system/applications/rofi/system-actions.sh" "🌐 Network Settings"
  '';

  systemActionsBluetooth = pkgs.writeShellScript "waybar-bluetooth-settings" ''
    exec "$HOME/.dotfiles/system/applications/rofi/system-actions.sh" "📱 Bluetooth"
  '';

  waybarConfig = {
    reload_style_on_change = true;
    layer = "top";
    position = "top";
    # Match the "floating pill" bar style
    spacing = 8;
    height = 34;
    margin-top = 8;
    margin-left = 10;
    margin-right = 10;

    "modules-left" = ["custom/launcher" "hyprland/workspaces"];
    "modules-center" = ["clock"];
    "modules-right" = [
      "group/tray-expander"
      "bluetooth"
      "network"
      "pulseaudio"
      "cpu"
      "battery"
      "custom/power-profile"
    ];

    "hyprland/workspaces" = {
      "on-click" = "activate";
      format = "{icon}";
      "format-icons" = {
        default = "";
        "1" = "1";
        "2" = "2";
        "3" = "3";
        "4" = "4";
        "5" = "5";
        "6" = "6";
        "7" = "7";
        "8" = "8";
        "9" = "9";
        "10" = "0";
      };
      "persistent-workspaces" = {
        "1" = [];
        "2" = [];
        "3" = [];
        "4" = [];
        "5" = [];
        "6" = [];
        "7" = [];
        "8" = [];
        "9" = [];
        "10" = [];
      };
    };

    "custom/launcher" = {
      format = "";
      "tooltip-format" = "Application launcher";
      "on-click" = "$HOME/.dotfiles/system/applications/rofi/rofi-wrapper.sh -show drun -font 'Monospace 15'";
      "on-click-right" = "kitty";
    };

    cpu = {
      interval = 5;
      format = "󰍛";
      "on-click" = "kitty -e btop";
    };

    clock = {
      format = "{:L%I:%M %p}";
      "format-alt" = "{:L%A %H:%M}";
      tooltip = false;
    };

    network = {
      "format-icons" = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
      format = "{icon}";
      "format-wifi" = "{icon}";
      "format-ethernet" = "󰀂";
      "format-disconnected" = "󰤮";
      "tooltip-format-wifi" = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
      "tooltip-format-ethernet" = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
      "tooltip-format-disconnected" = "Disconnected";
      interval = 3;
      spacing = 1;
      "on-click" = builtins.toString systemActionsNetwork;
    };

    battery = {
      format = "{capacity}% {icon}";
      "format-discharging" = "{icon}";
      "format-charging" = "{icon}";
      "format-plugged" = "";
      "format-icons" = {
        charging = [
          "󰢜"
          "󰂆"
          "󰂇"
          "󰂈"
          "󰢝"
          "󰂉"
          "󰢞"
          "󰂊"
          "󰂋"
          "󰂅"
        ];
        default = [
          "󰁺"
          "󰁻"
          "󰁼"
          "󰁽"
          "󰁾"
          "󰁿"
          "󰂀"
          "󰂁"
          "󰂂"
          "󰁹"
        ];
      };
      "format-full" = "󰂅";
      "tooltip-format-discharging" = "{power:>1.0f}W↓ {capacity}%";
      "tooltip-format-charging" = "{power:>1.0f}W↑ {capacity}%";
      interval = 5;
      states = {
        warning = 20;
        critical = 10;
      };
    };

    bluetooth = {
      format = "";
      "format-disabled" = "󰂲";
      "format-connected" = "󰂱";
      "format-no-controller" = "";
      "tooltip-format" = "Devices connected: {num_connections}";
      "on-click" = builtins.toString systemActionsBluetooth;
    };

    pulseaudio = {
      format = "{icon}";
      "on-click" = "pavucontrol";
      "on-click-right" = "pamixer -t";
      "tooltip-format" = "Playing at {volume}%";
      "scroll-step" = 5;
      "format-muted" = "";
      "format-icons" = {
        default = ["" "" ""];
      };
    };

    "custom/power-profile" = {
      "return-type" = "json";
      exec = builtins.toString powerProfileStatus;
      interval = 5;
      "on-click" = builtins.toString powerProfileMenu;
    };

    "group/tray-expander" = {
      orientation = "inherit";
      drawer = {
        "transition-duration" = 600;
        "children-class" = "tray-group-item";
      };
      modules = ["custom/expand-icon" "tray"];
    };

    "custom/expand-icon" = {
      format = "";
      tooltip = false;
    };

    tray = {
      "icon-size" = 14;
      spacing = 12;
    };
  };
in {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home-manager.users.${config.user} = {
      xdg.configFile."waybar/config.jsonc".text = builtins.toJSON waybarConfig;

      xdg.configFile."waybar/style.css".text = ''
        @define-color fg            #cdd6f4;
        @define-color bg            rgba(17, 17, 27, 0.55); /* bar */
        @define-color surface       rgba(30, 30, 46, 0.80); /* pills */
        @define-color border        rgba(255, 255, 255, 0.10);
        @define-color accent        #f38ba8;
        @define-color accent_text   #11111b;

        * {
          border: none;
          border-radius: 0;
          min-height: 0;
          font-family: 'JetBrainsMono Nerd Font';
          font-size: 12px;
          color: @fg;
        }

        window#waybar {
          background-color: @bg;
          border: 1px solid @border;
          border-radius: 18px;
        }

        /* Base “pill” look for modules */
        #custom-launcher,
        #workspaces,
        #clock,
        #bluetooth,
        #network,
        #pulseaudio,
        #cpu,
        #battery,
        #custom-power-profile,
        #group-tray-expander {
          background-color: @surface;
          border: 1px solid @border;
          border-radius: 999px;
          padding: 4px 10px;
          margin: 6px 6px;
        }

        /* Launcher: circular, a bit tighter */
        #custom-launcher {
          padding: 4px 10px;
          margin-left: 10px;
        }

        /* Center clock: slightly wider */
        #clock {
          padding: 4px 12px;
        }

        /* Workspaces: circles inside a pill */
        #workspaces {
          padding: 2px 6px;
        }

        #workspaces button {
          all: unset;
          min-width: 18px;
          min-height: 18px;
          padding: 0;
          margin: 3px;
          border-radius: 999px;
          background-color: rgba(205, 214, 244, 0.12);
          font-size: 0px; /* hide labels for inactive workspaces */
          opacity: 0.75;
        }

        #workspaces button.active,
        #workspaces button.focused {
          min-width: 28px;
          padding: 0 10px;
          background-color: @accent;
          color: @accent_text;
          font-size: 12px;
          opacity: 1;
        }

        #workspaces button.urgent {
          min-width: 28px;
          padding: 0 10px;
          background-color: rgba(250, 179, 135, 0.85);
          color: @accent_text;
          font-size: 12px;
          opacity: 1;
        }

        #workspaces button.empty {
          opacity: 0.25;
        }

        /* Tray group: keep inner modules transparent */
        #group-tray-expander #custom-expand-icon,
        #group-tray-expander #tray {
          background: transparent;
          border: none;
          margin: 0;
          padding: 0;
        }

        #group-tray-expander #custom-expand-icon {
          padding-right: 8px;
          opacity: 0.85;
        }

        tooltip {
          background: rgba(17, 17, 27, 0.92);
          border: 1px solid @border;
          border-radius: 10px;
          padding: 6px 8px;
        }

        .hidden {
          opacity: 0;
        }
      '';
    };
  };
}
