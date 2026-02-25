{
  config,
  pkgs,
  ...
}: let
  rofi = config.home-manager.users.${config.user}.programs.rofi.finalPackage;
in {
  # Adapted from:
  # https://gitlab.com/vahnrr/rofi-menus/-/blob/b1f0e8a676eda5552e27ef631b0d43e660b23b8e/scripts/rofi-power
  # A rofi powered menu to execute power related action.

  config.powerCommand = builtins.toString (
    pkgs.writeShellScript "powermenu" ''
      power_off=''
      reboot=''
      lock=''
      suspend='󰒲'
      hibernate='󰤄'
      hybrid_sleep='󰾪'
      log_out=''

      chosen=$(printf '%s;%s;%s;%s;%s;%s;%s\n' \
          "$power_off" \
          "$reboot" \
          "$lock" \
          "$suspend" \
          "$hibernate" \
          "$hybrid_sleep" \
          "$log_out" \
          | ${rofi}/bin/rofi \
              -theme-str '@import "power.rasi"' \
              -hover-select \
              -me-select-entry "" \
              -me-accept-entry MousePrimary \
              -dmenu \
              -sep ';' \
              -selected-row 3)

      confirm () {
          ${builtins.readFile ./rofi-prompt.sh}
      }

      case "$chosen" in
          "$power_off")
              # Extended timeout for graceful shutdown to allow apps to save state
              # Prevents Chrome "restore tabs" on startup by giving apps time to close properly
              confirm 'Shutdown?' && timeout 300 systemctl poweroff
              ;;

          "$reboot")
              # Extended timeout for graceful reboot to allow apps to save state
              # Prevents Chrome "restore tabs" on startup by giving apps time to close properly
              confirm 'Reboot?' && timeout 300 systemctl reboot
              ;;

          "$lock")
              loginctl lock-session
              ;;

          "$suspend")
              systemctl suspend
              ;;

          "$hibernate")
              # Hibernate requires swap space >= RAM size
              # Current setup: 62GB RAM, 39GB swap (insufficient)
              # To enable hibernation:
              # 1. Create swap file >= RAM size: sudo fallocate -l 64G /swapfile
              # 2. Set permissions: sudo chmod 600 /swapfile
              # 3. Format: sudo mkswap /swapfile
              # 4. Enable: sudo swapon /swapfile
              # 5. Add to NixOS config: boot.resumeDevice = "/swapfile";
              notify-send "Hibernate" "Not enough swap space for hibernation" -u critical
              ;;

          "$hybrid_sleep")
              # Hybrid sleep also requires sufficient swap space for hibernation
              # See hibernate notes above for requirements
              notify-send "Hybrid Sleep" "Not enough swap space for hybrid sleep" -u critical
              ;;

          "$log_out")
              confirm 'Logout?' && gnome-session-quit --logout --no-prompt
              ;;

          *) exit 1 ;;
      esac
    ''
  );
}
