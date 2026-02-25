{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.work-launcher;

  workScript = pkgs.writeShellScriptBin "work" ''
    #!/usr/bin/env bash

    # =============================================================================
    # Work Application Launcher
    # =============================================================================
    #
    # Description: Launches a customizable set of work applications with error handling
    # Usage: work (managed by NixOS configuration)
    #
    # Configuration:
    #   - Edit ~/.config/start_work_apps.conf to customize applications
    #   - One application per line
    #   - Lines starting with # are ignored
    #   - Empty lines are ignored
    #
    # Default applications: ${concatStringsSep ", " cfg.defaultApps}
    #
    # Author: Generated with Claude Code assistance
    # Version: 3.0 (NixOS Module)
    # =============================================================================

    CONFIG_FILE="$HOME/.config/start_work_apps.conf"
    DEFAULT_APPS=(${concatStringsSep " " (map (app: "\"${app}\"") cfg.defaultApps)})

    # Create config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        printf '%s\n' "''${DEFAULT_APPS[@]}" > "$CONFIG_FILE"
        echo "Created config file: $CONFIG_FILE"
    fi

    # Read applications from config (filter out comments and empty lines)
    apps=($(grep -v '^#' "$CONFIG_FILE" | grep -v '^$'))

    echo "Starting work applications..."
    echo "================================"

    # Launch each application
    failed_apps=()
    for app in "''${apps[@]}"; do
        if command -v "$app" >/dev/null 2>&1; then
            if "$app" &>/dev/null & then
                echo "✓ Opening $app..."
            else
                echo "✗ Failed to launch $app"
                failed_apps+=("$app")
            fi
        else
            echo "✗ $app not installed"
            failed_apps+=("$app")
        fi
        sleep ${toString cfg.launchDelay}
    done

    echo "================================"
    if [[ ''${#failed_apps[@]} -eq 0 ]]; then
        echo "✓ All applications launched successfully!"
    else
        echo "✗ Issues with: ''${failed_apps[*]}"
    fi
  '';

  workHyprScript = pkgs.writeShellScriptBin "work-hypr" ''
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v hyprctl >/dev/null 2>&1; then
      echo "Hyprland does not appear to be running (hyprctl missing)."
      exit 1
    fi

    if ! hyprctl monitors >/dev/null 2>&1; then
      echo "Unable to communicate with Hyprland (is it running?)."
      exit 1
    fi

    launch() {
      local workspace="$1"
      shift
      local cmd="$1"
      shift || true
      local extra="$*"
      if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Skipping $cmd (not installed)"
        return
      fi
      hyprctl dispatch exec "[workspace ''${workspace}] $cmd $extra" >/dev/null 2>&1 &
      sleep 0.4
    }

    launch_float() {
      local workspace="$1"
      shift
      local cmd="$1"
      shift || true
      local extra="$*"
      if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Skipping $cmd (not installed)"
        return
      fi
      hyprctl dispatch exec "[workspace ''${workspace}; float] $cmd $extra" >/dev/null 2>&1 &
      sleep 0.4
    }

    echo "Launching Hyprland workspace setup..."
    launch 1 kitty
    launch 2 code
    launch 3 brave
    launch 4 google-chrome-stable
    launch 5 firefox
    launch 6 obsidian
    launch_float 1 1password
    echo "Done."
  '';
in {
  options = {
    services.work-launcher = {
      enable = mkEnableOption "Work application launcher";

      defaultApps = mkOption {
        type = types.listOf types.str;
        default = ["spotify" "firefox" "brave" "code" "google-chrome-stable" "obsidian" "warp-terminal" "claude-desktop" "1password"];
        description = "Default applications to launch";
      };

      launchDelay = mkOption {
        type = types.int;
        default = 1;
        description = "Delay in seconds between launching applications";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [workScript workHyprScript];
  };
}
