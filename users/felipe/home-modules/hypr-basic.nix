{
  config,
  pkgs,
  lib,
  ...
}: {
  # Minimal but complete Hyprland config written directly by Home Manager.
  # This replaces all Omarchy-specific wiring.

  xdg.configFile."hypr/hyprland.conf".text = ''
    # Monitors: external DP-1 (165Hz) on the left, laptop eDP-1 (144Hz) on the right.
    # Hyprland will pick the closest available refresh rate (e.g. 164.54Hz for "165").
    monitor=DP-1,2560x1440@165,0x0,1
    monitor=eDP-1,1920x1080@144,auto,1

    # Pin workspaces to specific monitors:
    # - Workspaces 1–9 on the external display (DP-1)
    # - Workspace 10 (0 keybinding) on the laptop panel (eDP-1)
    workspace=1,monitor:DP-1,default:true
    workspace=2,monitor:DP-1
    workspace=3,monitor:DP-1
    workspace=4,monitor:DP-1
    workspace=5,monitor:DP-1
    workspace=6,monitor:DP-1
    workspace=7,monitor:DP-1
    workspace=8,monitor:DP-1
    workspace=9,monitor:DP-1
    workspace=10,monitor:eDP-1

    # Environment
    env = XCURSOR_THEME,Bibata-Modern-Ice
    env = XCURSOR_SIZE,16
    env = HYPRCURSOR_SIZE,16

    # Input configuration
    input {
      kb_layout = us
      kb_variant = altgr-intl
      kb_options = ctrl:nocaps

      touchpad {
        natural_scroll = true
        tap-to-click = true
      }
    }

    general {
      gaps_in = 5
      gaps_out = 10
      border_size = 2
      layout = dwindle
    }

    decoration {
      rounding = 4
      active_opacity = 1.0
      inactive_opacity = 0.92
      fullscreen_opacity = 1.0
      blur {
        enabled = false
      }
      shadow {
        enabled = true
        range = 4
        render_power = 3
      }
    }

    animations {
      enabled = true
      bezier = easeOut,0.05,0.9,0.1,1.0
      animation = windows,1,1,default
      animation = windowsOut,1,1,default, popin 80%
      animation = border,1,1,default
      animation = fade,1,1,default
      animation = workspaces,1,1,default
    }

    misc {
      disable_hyprland_logo = false
      disable_splash_rendering = false
      focus_on_activate = true
    }

    # Window rules
    windowrulev2 = size 1200 800, class:^(1Password)$
    windowrulev2 = center, class:^(1Password)$

    xwayland {
      force_zero_scaling = true
    }

    # Applications
    $terminal = kitty
    $rofi = /home/felipe/.dotfiles/system/applications/rofi/rofi-wrapper.sh
    $menu = $rofi -show drun
    $filemanager = dolphin

    exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_DATA_DIRS PATH
    exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_DATA_DIRS PATH
    exec-once = ${pkgs.swww}/bin/swww-daemon --quiet
    exec-once = /home/felipe/.local/bin/wallpaper-randomize
    exec-once = waybar
    exec-once = swaync
    exec-once = blueman-applet

    # Ensure the compositor cursor is set (theme + size)
    exec-once = hyprctl setcursor Bibata-Modern-Ice 16

    # Re-apply workspace-to-monitor pinning on startup and after monitor hotplug.
    exec-once = /home/felipe/.local/bin/hypr-pin-workspaces --watch

    # Clipboard history (cliphist)
    exec-once = wl-paste --watch cliphist store

    # Keybindings -------------------------------------------------------

    # Launch terminal / menu
    bind = SUPER, Return, exec, $terminal
    bind = SUPER, D, exec, $menu
    bind = SUPER, E, exec, $filemanager
    bind = SUPER, N, exec, swaync-client -t
    bind = ALT, W, exec, $rofi -show window -modi window

    # Rofi shortcuts (mirroring GNOME custom keybindings)
    bind = ALT, N, exec, $menu
    bind = ALT, E, exec, $rofi -show emoji
    bind = ALT, F, exec, $rofi -show filebrowser -modi filebrowser
    bind = ALT, S, exec, $rofi -show system-actions -modi system-actions:/home/felipe/.dotfiles/system/applications/rofi/system-actions.sh
    bind = ALT SHIFT, N, exec, $rofi -show network -modi network:/home/felipe/.dotfiles/system/applications/rofi/network-switcher.sh
    bind = ALT, V, exec, /home/felipe/.dotfiles/system/scripts/cliphist-rofi.sh
    bind = ALT, T, exec, /home/felipe/.dotfiles/system/scripts/translate.sh
    bind = ALT SHIFT, T, exec, /home/felipe/.dotfiles/system/scripts/translate-selection.sh

    # Clipboard history navigation (similar to GNOME clipboard manager)
    bind = ALT, C, exec, /home/felipe/.dotfiles/system/scripts/cliphist-cycle.sh next
    bind = ALT SHIFT, C, exec, /home/felipe/.dotfiles/system/scripts/cliphist-cycle.sh prev

    # Close / kill / exit
    bind = SUPER, Q, killactive
    bind = SUPER SHIFT, Q, exec, hyprctl dispatch exit 0

    # Fullscreen and floating
    bind = SUPER, F, fullscreen
    bind = SUPER, V, togglefloating

    # Focus movement and workspace helpers
    bind = SUPER, H, movefocus, l
    bind = SUPER, L, movefocus, r
    bind = SUPER, K, movefocus, u
    bind = SUPER, J, movefocus, d
    bind = SUPER, TAB, workspace, previous

    # Move focused window to previous/next workspace
    bind = SUPER SHIFT, H, movetoworkspace, e-1
    bind = SUPER SHIFT, L, movetoworkspace, e+1

    # Focus/move across monitors
    bind = SUPER CTRL, H, focusmonitor, -1
    bind = SUPER CTRL, L, focusmonitor, +1
    bind = SUPER CTRL SHIFT, H, movewindow, mon:-1
    bind = SUPER CTRL SHIFT, L, movewindow, mon:+1

    # Workspace switching (1–10, 0 = 10)
    bind = SUPER, 1, workspace, 1
    bind = SUPER, 2, workspace, 2
    bind = SUPER, 3, workspace, 3
    bind = SUPER, 4, workspace, 4
    bind = SUPER, 5, workspace, 5
    bind = SUPER, 6, workspace, 6
    bind = SUPER, 7, workspace, 7
    bind = SUPER, 8, workspace, 8
    bind = SUPER, 9, workspace, 9
    bind = SUPER, 0, workspace, 10

    bind = SUPER SHIFT, 1, movetoworkspace, 1
    bind = SUPER SHIFT, 2, movetoworkspace, 2
    bind = SUPER SHIFT, 3, movetoworkspace, 3
    bind = SUPER SHIFT, 4, movetoworkspace, 4
    bind = SUPER SHIFT, 5, movetoworkspace, 5
    bind = SUPER SHIFT, 6, movetoworkspace, 6
    bind = SUPER SHIFT, 7, movetoworkspace, 7
    bind = SUPER SHIFT, 8, movetoworkspace, 8
    bind = SUPER SHIFT, 9, movetoworkspace, 9
    bind = SUPER SHIFT, 0, movetoworkspace, 10

    # Resize windows with arrow keys (keeps monitor move shortcuts free on H/L)
    bind = SUPER CTRL, LEFT, resizeactive, -20 0
    bind = SUPER CTRL, RIGHT, resizeactive, 20 0
    bind = SUPER CTRL, UP, resizeactive, 0 -20
    bind = SUPER CTRL, DOWN, resizeactive, 0 20

    # Volume
    bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bind = , XF86AudioMute,        exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle

    # Brightness (laptop internal display)
    bind = , XF86MonBrightnessUp,   exec, brightnessctl set +5%
    bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

    # Display layout toggle (cycle extend/internal/external/mirror, like GNOME Super+P)
    bind = SUPER, P, exec, /home/felipe/.dotfiles/system/scripts/toggle-displays.sh
    bind = SUPER SHIFT, P, exec, /home/felipe/.local/bin/hypr-pin-workspaces

    # Power profiles
    bind = SUPER ALT, 1, exec, powerprofilesctl set power-saver
    bind = SUPER ALT, 2, exec, powerprofilesctl set balanced
    bind = SUPER ALT, 3, exec, powerprofilesctl set performance

    # Screenshots (grim + slurp, also copy to clipboard)
    bind = , Print, exec, sh -c 'f="$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"; grim -g "$(slurp)" - | tee "$f" | wl-copy --type image/png'
    bind = SHIFT, Print, exec, sh -c 'f="$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"; grim - | tee "$f" | wl-copy --type image/png'
  '';

  home.file.".local/bin/wallpaper-randomize" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      SWWW="${pkgs.swww}/bin/swww"
      SWWW_DAEMON="${pkgs.swww}/bin/swww-daemon"

      start_daemon() {
        if "$SWWW" query >/dev/null 2>&1; then
          return 0
        fi

        "$SWWW_DAEMON" --quiet >/dev/null 2>&1 &
        disown || true
      }

      wait_ready() {
        for _ in {1..50}; do
          if "$SWWW" query >/dev/null 2>&1; then
            return 0
          fi
          sleep 0.1
        done
        return 1
      }

      pick_from_dir() {
        local dir="$1"
        [[ -d "$dir" ]] || return 1

        local picked
        picked="$(
          find "$dir" -type f \( \
            -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \
          \) -print 2>/dev/null | shuf -n 1 || true
        )"

        [[ -n "$picked" ]] || return 1
        printf '%s\n' "$picked"
      }

      if [[ ! -x "$SWWW" || ! -x "$SWWW_DAEMON" ]]; then
        exit 0
      fi

      if [[ -f "$HOME/.config/user-dirs.dirs" ]]; then
        # shellcheck disable=SC1090
        source "$HOME/.config/user-dirs.dirs"
      fi

      pictures_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}"

      candidates=()
      if [[ -n "''${WALLPAPER_DIR:-}" ]]; then
        candidates+=("$WALLPAPER_DIR")
      fi
      candidates+=(
        "$pictures_dir/Wallpapers"
        "$pictures_dir/BingWallpaper"
        "$HOME/.local/share/wallpapers"
      )

      img="''${1:-}"
      if [[ -z "$img" ]]; then
        for dir in "''${candidates[@]}"; do
          img="$(pick_from_dir "$dir" || true)"
          [[ -n "$img" ]] && break
        done
      fi

      if [[ -z "$img" ]]; then
        fallback=(
          "${pkgs.nixos-artwork.wallpapers.nineish-catppuccin-mocha.passthru.gnomeFilePath}"
          "${pkgs.nixos-artwork.wallpapers.nineish-catppuccin-mocha-alt.passthru.gnomeFilePath}"
          "${pkgs.nixos-artwork.wallpapers.catppuccin-mocha.passthru.gnomeFilePath}"
          "${pkgs.nixos-artwork.wallpapers.catppuccin-macchiato.passthru.gnomeFilePath}"
        )
        img="$(printf '%s\n' "''${fallback[@]}" | shuf -n 1)"
      fi

      [[ -n "$img" ]] || exit 0

      start_daemon || exit 0
      wait_ready || exit 0

      "$SWWW" img "$img" \
        --transition-type random \
        --transition-duration 1.2 \
        --transition-fps 60 \
        --transition-bezier .2,.8,.2,1
    '';
  };

  home.file.".local/bin/hypr-pin-workspaces" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      apply() {
        if ! command -v hyprctl >/dev/null 2>&1; then
          return 0
        fi
        if ! command -v jq >/dev/null 2>&1; then
          return 0
        fi

        local monitors_json workspaces_json existing_ids internal external
        monitors_json="$(hyprctl monitors -j 2>/dev/null || true)"
        [[ -n "$monitors_json" ]] || return 0

        internal="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.name | test("^(eDP|LVDS|DSI)")) | .name' | head -n1)"

        if printf '%s' "$monitors_json" | jq -e '.[] | select(.name == "DP-1")' >/dev/null 2>&1; then
          external="DP-1"
        else
          external="$(printf '%s' "$monitors_json" | jq -r --arg internal "$internal" '.[] | select(.name != $internal) | .name' | head -n1)"
        fi

        [[ -n "$external" && -n "$internal" ]] || return 0

        workspaces_json="$(hyprctl workspaces -j 2>/dev/null || true)"
        existing_ids="$(printf '%s' "$workspaces_json" | jq -r '.[].id' | tr '\n' ' ')"

        for ws in 1 2 3 4 5 6 7 8 9; do
          if [[ " $existing_ids " == *" $ws "* ]]; then
            hyprctl dispatch moveworkspacetomonitor "$ws" "$external" >/dev/null 2>&1 || true
          fi
        done

        # Workspace 10 is bound to SUPER+0 in this config.
        if [[ " $existing_ids " == *" 10 "* ]]; then
          hyprctl dispatch moveworkspacetomonitor 10 "$internal" >/dev/null 2>&1 || true
        fi
      }

      watch() {
        # Run once after Hyprland is ready
        sleep 0.5
         apply

         local runtime_dir sock
         runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$UID}"

        if [[ -z "''${HYPRLAND_INSTANCE_SIGNATURE-}" ]]; then
          # Not running inside Hyprland; nothing to watch.
          return 0
        fi

        sock="$runtime_dir/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
        [[ -S "$sock" ]] || return 0

        # Listen for hotplug events and re-apply pinning.
        # Using OpenBSD netcat (nc) which supports UNIX domain sockets.
        nc -U "$sock" | while IFS= read -r line; do
          case "$line" in
            monitoradded*|monitorremoved*)
              apply
              ;;
          esac
        done
      }

      case "''${1-}" in
        --watch) watch ;;
        *) apply ;;
      esac
    '';
  };

  systemd.user.services.wallpaper-randomize = {
    Unit = {
      Description = "Randomize wallpaper (swww)";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/wallpaper-randomize";
    };
  };

  systemd.user.timers.wallpaper-randomize = {
    Unit = {Description = "Periodically randomize wallpaper";};
    Timer = {
      OnBootSec = "1m";
      OnUnitActiveSec = "2h";
      Persistent = true;
    };
    Install = {WantedBy = ["timers.target"];};
  };
}
