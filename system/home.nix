{
  pkgs,
  inputs,
  config,
  lib,
  hmStateVersion,
  ...
}: {
  # home-terminal.nix owns the cross-host terminal layer: shell/git/session/ssh
  # modules, kitty, fzf, atuin, zoxide, direnv, neovim, ai-env and tmuxinator.
  # This module adds only what is specific to a graphical NixOS host.
  imports = [
    ./home-terminal.nix
    ../users/felipe/home-modules/hypr-basic.nix
    ./modules/micro.nix
    ./packages/cli.nix
  ];

  # genericLinux is for Nix-on-a-foreign-distro; on NixOS it must stay off.
  targets.genericLinux.enable = false;

  home.packages = let
    packages = import ./packages {inherit pkgs inputs;};
  in
    packages.userPackages;

  # AI harness configurations (editable without rebuild)
  home.file.".aider.conf.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/export/harnesses/aider.conf.yml";
  xdg.configFile."hermes/config.default.yaml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/export/hermes/config.default.yaml";

  # Zed editor configuration
  xdg.configFile."zed/settings.json".text = builtins.toJSON {
    # Appearance
    theme = "Catppuccin Mocha";
    buffer_font_family = "JetBrainsMono Nerd Font";
    buffer_font_size = 14;
    ui_font_family = "JetBrainsMono Nerd Font";
    ui_font_size = 14;

    # Editor behavior
    vim_mode = true;
    cursor_blink = false;
    relative_line_numbers = true;
    tab_size = 2;
    soft_wrap = "editor_width";
    format_on_save = "on";
    autosave = "on_focus_change";

    # Terminal
    terminal = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = 12;
      shell = "system";
    };

    # Telemetry
    telemetry = {
      metrics = false;
      diagnostics = false;
    };

    # Git integration
    git = {
      inline_blame = {
        enabled = true;
      };
    };

    # File types
    file_types = {
      Nix = ["nix"];
    };

    # Languages
    languages = {
      Nix = {
        tab_size = 2;
        formatter = {
          external = {
            command = "alejandra";
            arguments = ["-q"];
          };
        };
      };
      JavaScript = {
        tab_size = 2;
        formatter = "language_server";
      };
      TypeScript = {
        tab_size = 2;
        formatter = "language_server";
      };
    };

    # Inlay hints
    inlay_hints = {
      enabled = true;
    };

    # Project panel
    project_panel = {
      dock = "left";
      default_width = 240;
    };
  };

  # programs.rofi = {
  #   enable = true;
  #   terminal = "${pkgs.kitty}/bin/kitty"; # Using your existing terminal
  #   theme = "DarkBlue";
  #   extraConfig = {
  #     modi = "drun,run,window,ssh,file-browser:/home/felipe/.dotfiles/system/applications/rofi/file-browser.sh,system-actions:/home/felipe/.dotfiles/system/applications/rofi/system-actions.sh";
  #     show-icons = true;
  #     sort = true;
  #   };
  #   plugins = with pkgs; [
  #     rofi-calc
  #     rofi-emoji
  #   ];
  # };

  # Set up GNOME keybindings
  services.gnome-keyring.enable = true;

  # GNOME extensions management
  dconf.enable = true;

  dconf.settings = {
    "org/blueman/general" = {
      plugin-list = ["!ConnectionNotifier"];
    };

    "org/gnome/desktop/input-sources" = {
      sources = [(lib.hm.gvariant.mkTuple ["xkb" "us+altgr-intl"])];
      xkb-options = ["ctrl:nocaps"];
    };

    # GNOME Shell keybindings
    "org/gnome/shell/keybindings" = {
      show-screen-recording-ui = ["<Shift><Alt>r"];
      show-screenshot-ui = ["<Shift>Print"];
      screenshot = [""];
      screenshot-window = [""];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-launcher/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-window/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-emoji/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/file-manager/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/qutebrowser/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/system-monitor/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/translate/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/translate-selection/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-saver/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-balanced/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-performance/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tile-left/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tile-right/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tile-up/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tile-down/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-file-browser/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-system/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/qr-scan/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-window" = {
      name = "Rofi window";
      command = "/home/felipe/.dotfiles/system/applications/rofi/rofi-wrapper.sh -show window -modi window";
      binding = "<Alt>w";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-launcher" = {
      name = "Rofi Launcher ";
      command = "/home/felipe/.dotfiles/system/applications/rofi/rofi-wrapper.sh -show drun";
      binding = "<Alt>n";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-emoji" = {
      name = "Rofi emoji";
      command = "/home/felipe/.dotfiles/system/applications/rofi/rofi-wrapper.sh -show emoji";
      binding = "<Alt>e";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal" = {
      name = "Terminal";
      command = "kitty";
      binding = "<Super>Return";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/file-manager" = {
      name = "File Manager";
      command = "dolphin";
      binding = "<Super>e";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/qutebrowser" = {
      name = "Qutebrowser";
      command = "qutebrowser";
      binding = "<Super>b";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/system-monitor" = {
      name = "System Monitor";
      command = "kitty -e btop";
      binding = "<Super>t";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot" = {
      name = "Flameshot Screenshot";
      command = "flameshot gui";
      binding = "Print";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/qr-scan" = {
      name = "QR Scan to Clipboard";
      command = "/home/felipe/.dotfiles/system/scripts/qr-scan.sh";
      binding = "<Ctrl><Shift>Print";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/translate" = {
      name = "Quick Translate";
      command = "/home/felipe/.dotfiles/system/scripts/translate.sh";
      binding = "<Alt>t";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/translate-selection" = {
      name = "Translate Selection";
      command = "/home/felipe/.dotfiles/system/scripts/translate-selection.sh";
      binding = "<Shift><Alt>t";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-saver" = {
      name = "Power Saver Mode";
      command = "powerprofilesctl set power-saver";
      binding = "<Super><Alt>1";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-balanced" = {
      name = "Balanced Power Mode";
      command = "powerprofilesctl set balanced";
      binding = "<Super><Alt>2";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/power-performance" = {
      name = "Performance Mode";
      command = "powerprofilesctl set performance";
      binding = "<Super><Alt>3";
    };

    # Enhanced window tiling (works with tiling-assistant)
    # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tile-left" = {
    #   name = "Tile Window Left Half";
    #   command = "busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Extensions.TilingAssistant TileWindow 'ssi' 'left' 50 1";
    #   binding = "<Super>Left";
    # };

    # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tile-right" = {
    #   name = "Tile Window Right Half";
    #   command = "busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Extensions.TilingAssistant TileWindow 'ssi' 'right' 50 1";
    #   binding = "<Super>Right";
    # };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tile-up" = {
      name = "Tile Window Top Half";
      command = "busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Extensions.TilingAssistant TileWindow 'ssi' 'top' 50 1";
      binding = "<Super>Up";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tile-down" = {
      name = "Tile Window Bottom Half";
      command = "busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Extensions.TilingAssistant TileWindow 'ssi' 'bottom' 50 1";
      binding = "<Super>Down";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-file-browser" = {
      name = "Rofi File Browser";
      command = let
        pluginAvailable =
          (pkgs ? rofi-file-browser-extended)
          || ((pkgs ? rofiPlugins) && ((pkgs.rofiPlugins ? file-browser-extended) || (pkgs.rofiPlugins ? file-browser)));
      in
        if pluginAvailable
        then "/home/felipe/.dotfiles/system/applications/rofi/rofi-wrapper.sh -show filebrowser -modi filebrowser"
        else "/home/felipe/.dotfiles/system/applications/rofi/rofi-wrapper.sh -show file-browser -modi file-browser:/home/felipe/.dotfiles/system/applications/rofi/file-browser.sh";
      binding = "<Alt>f";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-system" = {
      name = "Rofi System Actions";
      command = "/home/felipe/.dotfiles/system/applications/rofi/rofi-wrapper.sh -show system-actions -modi system-actions:/home/felipe/.dotfiles/system/applications/rofi/system-actions.sh";
      binding = "<Alt>s";
    };

    # GNOME Shell settings for stability
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-panel@jderose9.github.com"
        "tiling-assistant@leleat-on-github"
        "system-monitor-indicator@mknap.com"
        "clipboard-indicator@tudmotu.com"
        "AlphabeticalAppGrid@stuarthayhurst"
        "mediacontrols@cliffniff.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
        "native-window-placement@gnome-shell-extensions.gcampax.github.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "window-list@gnome-shell-extensions.gcampax.github.com"
        "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
      ];
      disable-user-extensions = false;
      development-tools = false;
    };

    # Comprehensive GNOME keyboard shortcuts for window management
    "org/gnome/desktop/wm/keybindings" = {
      # Window management
      close = ["<Alt>F4" "<Super>q"];
      minimize = ["<Super>h"];
      maximize = ["<Super>f"];
      unmaximize = ["<Super>f"];
      toggle-maximized = ["<Super>f"];

      # Window focus and movement
      move-to-workspace-left = ["<Shift><Super>Left"];
      move-to-workspace-right = ["<Shift><Super>Right"];
      move-to-workspace-up = ["<Shift><Super>Up"];
      move-to-workspace-down = ["<Shift><Super>Down"];

      # Switch between windows
      switch-windows = ["<Alt>Tab"];
      switch-windows-backward = ["<Shift><Alt>Tab"];
      switch-applications = ["<Super>Tab"];
      switch-applications-backward = ["<Shift><Super>Tab"];

      # Workspace navigation
      switch-to-workspace-left = ["<Super><Ctrl>Left"];
      switch-to-workspace-right = ["<Super><Ctrl>Right"];
      switch-to-workspace-up = ["<Super><Ctrl>Up"];
      switch-to-workspace-down = ["<Super><Ctrl>Down"];

      # Direct workspace access
      switch-to-workspace-1 = ["<Super>1"];
      switch-to-workspace-2 = ["<Super>2"];
      switch-to-workspace-3 = ["<Super>3"];
      switch-to-workspace-4 = ["<Super>4"];
      switch-to-workspace-5 = ["<Super>5"];
      switch-to-workspace-6 = ["<Super>6"];
      switch-to-workspace-7 = ["<Super>7"];
      switch-to-workspace-8 = ["<Super>8"];
      switch-to-workspace-9 = ["<Super>9"];
      switch-to-workspace-10 = ["<Super>0"];

      # Move window to workspace
      move-to-workspace-1 = ["<Shift><Super>1"];
      move-to-workspace-2 = ["<Shift><Super>2"];
      move-to-workspace-3 = ["<Shift><Super>3"];
      move-to-workspace-4 = ["<Shift><Super>4"];
      move-to-workspace-5 = ["<Shift><Super>5"];
      move-to-workspace-6 = ["<Shift><Super>6"];
      move-to-workspace-7 = ["<Shift><Super>7"];
      move-to-workspace-8 = ["<Shift><Super>8"];
      move-to-workspace-9 = ["<Shift><Super>9"];
      move-to-workspace-10 = ["<Shift><Super>0"];

      # Tiling-style window management
      toggle-fullscreen = ["<Super>F11"];

      switch-input-source = [""];
      switch-input-source-backward = [""];
    };

    # Disable GNOME Terminal's Alt+number tab switching so tmux gets the keys
    "org/gnome/terminal/legacy/keybindings" = {
      switch-to-tab-1 = "disabled";
      switch-to-tab-2 = "disabled";
      switch-to-tab-3 = "disabled";
      switch-to-tab-4 = "disabled";
      switch-to-tab-5 = "disabled";
      switch-to-tab-6 = "disabled";
      switch-to-tab-7 = "disabled";
      switch-to-tab-8 = "disabled";
      switch-to-tab-9 = "disabled";
    };
  };

  # Yazi configuration is provided by users/felipe/home-modules/shell.nix (felipe only)

  # Appended to home-terminal.nix's entries; cargo/go bins are desktop-host only.
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
  ];

  # ActivityWatch service configuration
  services.activitywatch = {
    enable = true;
    package = pkgs.activitywatch;
    watchers = {
      aw-watcher-afk = {};
      aw-watcher-window = {};
    };
    settings = {
      aw-server = {
        port = 5600;
        host = "127.0.0.1";
      };
    };
  };

  # Fix ActivityWatch watchers by setting DISPLAY environment variable
  systemd.user.services = {
    hermes-dashboard = {
      Unit = {
        Description = "Hermes Agent Dashboard";
        After = ["network.target"];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "${config.home.homeDirectory}/.hermes/hermes-agent";
        Environment = "HOME=${config.home.homeDirectory}";
        EnvironmentFile = "-%h/.hermes/.env";
        ExecStart = "${config.home.homeDirectory}/.hermes/hermes-agent/venv/bin/hermes dashboard --skip-build --no-open --port 9119 --host 0.0.0.0 --insecure";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    activitywatch-watcher-aw-watcher-window = {
      Service = {
        Environment = "DISPLAY=:0";
      };
    };

    activitywatch-watcher-aw-watcher-afk = {
      Service = {
        Environment = "DISPLAY=:0";
      };
    };
  };

  # Automatically adjust monitor brightness and color with ddcutil based on time
  systemd.user.services.ddc-schedule = {
    Unit = {
      Description = "DDC/CI monitor schedule";
      After = ["graphical-session.target"]; # run in user session
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /home/felipe/.dotfiles/system/scripts/ddc-schedule.sh";
      Environment = [
        "TARGET_MODEL=NZXT" # change or unset to affect all DDC displays
      ];
    };
    Install = {WantedBy = ["default.target"];};
  };

  systemd.user.timers.ddc-schedule = {
    Unit = {
      Description = "Run DDC/CI monitor schedule hourly";
    };
    Timer = {
      OnCalendar = "hourly"; # evaluate per-hour which profile applies
      Persistent = true; # catch up after suspend/boot
      OnBootSec = "1m"; # apply shortly after login
    };
    Install = {WantedBy = ["timers.target"];};
  };

  # Auto theme switcher based on time of day
  systemd.user.services.auto-theme = {
    Unit = {
      Description = "Auto-switch dark/light theme based on time";
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /home/felipe/.dotfiles/system/scripts/auto-theme";
    };
    Install = {WantedBy = ["default.target"];};
  };

  systemd.user.timers.auto-theme = {
    Unit = {
      Description = "Run auto-theme switcher periodically";
    };
    Timer = {
      OnCalendar = "*:0/5"; # every 5 minutes
      Persistent = true; # catch up after suspend/boot
      OnBootSec = "1m"; # apply shortly after login
    };
    Install = {WantedBy = ["timers.target"];};
  };

  # systemd.user.services = {
  #   aw-server = {
  #     Unit = {
  #       Description = "ActivityWatch Server";
  #       After = ["network.target"];
  #     };
  #     Service = {
  #       ExecStart = "${pkgs.activitywatch}/bin/aw-server";
  #     };
  #     Install = {
  #       WantedBy = ["default.target"];
  #     };
  #   };
  #   aw-watcher-afk = {
  #     Unit = {
  #       Description = "ActivityWatch AFK Watcher";
  #     };
  #     Service = {
  #       ExecStart = "${pkgs.activitywatch}/bin/aw-watcher-afk";
  #     };
  #     Install = {
  #       WantedBy = ["default.target"];
  #     };
  #   };
  #   aw-watcher-window = {
  #     Unit = {
  #       Description = "ActivityWatch Window Watcher";
  #     };
  #     Service = {
  #       ExecStart = "${pkgs.activitywatch}/bin/aw-watcher-window";
  #     };
  #     Install = {
  #       WantedBy = ["default.target"];
  #     };
  #   };
  # };

  # kitty, zoxide, fzf and atuin are configured in home-terminal.nix.

  home.sessionVariables = {
    GOOGLE_CLOUD_PROJECT = "wired-effort-416222";
  };

  # Set VLC as default for video and audio files
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Video formats
      "video/mp4" = ["vlc.desktop"];
      "video/x-matroska" = ["vlc.desktop"];
      "video/webm" = ["vlc.desktop"];
      "video/avi" = ["vlc.desktop"];
      "video/x-msvideo" = ["vlc.desktop"];
      "video/quicktime" = ["vlc.desktop"];
      "video/x-flv" = ["vlc.desktop"];
      "video/mpeg" = ["vlc.desktop"];
      "video/ogg" = ["vlc.desktop"];
      "video/3gpp" = ["vlc.desktop"];
      "video/3gpp2" = ["vlc.desktop"];
      "video/x-ms-wmv" = ["vlc.desktop"];
      "application/x-mpegURL" = ["vlc.desktop"];
      "application/vnd.apple.mpegurl" = ["vlc.desktop"];
      # Audio formats
      "audio/mpeg" = ["vlc.desktop"];
      "audio/mp3" = ["vlc.desktop"];
      "audio/flac" = ["vlc.desktop"];
      "audio/x-flac" = ["vlc.desktop"];
      "audio/ogg" = ["vlc.desktop"];
      "audio/x-vorbis+ogg" = ["vlc.desktop"];
      "audio/wav" = ["vlc.desktop"];
      "audio/x-wav" = ["vlc.desktop"];
      "audio/aac" = ["vlc.desktop"];
      "audio/mp4" = ["vlc.desktop"];
      "audio/x-m4a" = ["vlc.desktop"];
      "audio/x-ms-wma" = ["vlc.desktop"];
      "audio/webm" = ["vlc.desktop"];
      "audio/opus" = ["vlc.desktop"];
      "audio/x-opus+ogg" = ["vlc.desktop"];
      "audio/aiff" = ["vlc.desktop"];
      "audio/x-aiff" = ["vlc.desktop"];
    };
  };

  # direnv and programs.home-manager are enabled in home-terminal.nix.
}
