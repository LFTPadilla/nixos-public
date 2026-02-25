{
  config,
  pkgs,
  ...
}: let
  rofi = config.home-manager.users.${config.user}.programs.rofi.finalPackage;
in {
  # Adapted from:
  # A rofi powered menu to execute brightness choices.

  config.brightnessCommand = builtins.toString (
    pkgs.writeShellScript "brightness" ''

      dimmer="󰃝"
      medium="󰃟"
      brighter="󰃠"

      chosen=$(printf '%s;%s;%s\n' \
          "$dimmer" \
          "$medium" \
          "$brighter" \
          | ${rofi}/bin/rofi \
              -theme-str '@import "brightness.rasi"' \
              -hover-select \
              -me-select-entry "" \
              -me-accept-entry MousePrimary \
              -dmenu \
              -sep ';' \
              -selected-row 1)

      # Auto-detect displays and set brightness for all
      set_brightness() {
          local brightness_level="$1"

          # Get list of detected displays
          displays=$(${pkgs.ddcutil}/bin/ddcutil detect --brief 2>/dev/null | grep -oP 'Display \K[0-9]+' || echo "")

          if [ -z "$displays" ]; then
              # No displays detected, try common display numbers as fallback
              displays="1 2"
          fi

          # Set brightness for each detected display
          for display in $displays; do
              ${pkgs.ddcutil}/bin/ddcutil --display "$display" setvcp 10 "$brightness_level" 2>/dev/null &
          done

          # Wait for all background jobs to complete
          wait
      }

      case "$chosen" in
          "$dimmer")
              set_brightness 25
              ;;

          "$medium")
              set_brightness 75
              ;;

          "$brighter")
              set_brightness 100
              ;;

          *) exit 1 ;;
      esac

    ''
  );
}
