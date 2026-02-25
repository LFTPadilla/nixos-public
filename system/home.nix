{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    ../users/felipe/home-modules/shell.nix
    ../users/felipe/home-modules/hypr-basic.nix
    ./modules/micro.nix
    ./packages/cli.nix
  ];
  home.username = "felipe";
  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = let
    packages = import ./packages {inherit pkgs inputs;};
  in
    packages.userPackages;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Neovim Lua configuration (mini VSCode) from this dotfiles repo
  # Use an out-of-store symlink so the config is editable without rebuilding.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/nvim";

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
  };

  # Yazi configuration is provided by users/felipe/home-modules/shell.nix (felipe only)

  # Add GOPATH bins to PATH so helper scripts and `go install` binaries are available
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
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

  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Mocha"; #"One Half Light";  # "Catppuccin-Latte"; #
    settings = {
      # Font configuration with ligature support
      font_family = "JetBrainsMono Nerd Font";
      font_size = 12;
      adjust_line_height = "120%";
      disable_ligatures = "cursor";
      background_opacity = "1.0";
      window_scaling = 200;
      # Advanced font features
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      # Nerd Font symbol mapping
      symbol_map = "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A2,U+E0A3,U+E0B0-U+E0B3,U+E0B4-U+E0C8,U+E0CA,U+E0CC-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6B1,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F372,U+F400-U+F532,U+F500-U+FD46,U+F0001-U+F1AF0 Symbols Nerd Font Mono";

      # Performance & behavior
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = "yes";
      close_on_child_death = "yes";
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty";
      update_check_interval = 0;

      # Terminal behavior
      scrollback_lines = 50000;
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";
      scrollback_pager_history_size = 256;
      wheel_scroll_multiplier = "5.0";
      touch_scroll_multiplier = "1.0";

      # Window layout
      window_padding_width = "4";
      hide_window_decorations = "false";
      confirm_os_window_close = 0;
      enabled_layouts = "tall,stack,fat,grid,splits";
      inactive_text_alpha = "0.8";

      # URL handling
      url_style = "double";
      open_url_with = "xdg-open";
      url_prefixes = "http https file ftp gemini irc gopher mailto news git";
      detect_urls = "yes";

      # Advanced terminal features
      clipboard_control = "write-clipboard write-primary no-append";
      term = "xterm-kitty";
      # shell = "${pkgs.tmux}/bin/tmux new-session -A -s main";
      shell_integration = "enabled";
      allow_hyperlinks = "yes";

      # Performance tweaks
      cursor_blink_interval = 0;
      cursor_stop_blinking_after = 0;
      enable_audio_bell = false;
      visual_bell_duration = "0.0";
      window_alert_on_bell = "yes";
      bell_on_tab = "no";
    };

    keybindings = {
      # Navigation
      "ctrl+shift+h" = "neighboring_window left";
      "ctrl+shift+j" = "neighboring_window down";
      "ctrl+shift+k" = "neighboring_window up";

      # Window management
      "ctrl+shift+enter" = "new_window_with_cwd";
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+q" = "close_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";

      # Layout management
      "ctrl+shift+l" = "next_layout";
      "ctrl+shift+z" = "toggle_layout stack";

      # Font size
      "ctrl+shift+equal" = "change_font_size all +2.0";
      "ctrl+shift+minus" = "change_font_size all -2.0";
      "ctrl+shift+backspace" = "change_font_size all 0";

      # Scrolling
      "shift+page_up" = "scroll_page_up";
      "shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";

      # Copy/Paste
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";

      # Miscellaneous
      "ctrl+shift+f" = "show_scrollback";
      "ctrl+shift+u" = "unicode_input";
      "ctrl+shift+delete" = "clear_terminal reset active";
    };
  };

  programs.zoxide.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = ["--height" "40%" "--border" "--layout=reverse"];
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      search_mode = "prefix";
      style = "compact";
      inline_height = 12;
      inline_height_shell_up_key_binding = 12;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Felipe Tejada";
        email = "felipe.tejada@kommit.co";
      };
      alias = {
        lol = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)<%an>%Creset' --abbrev-commit";
        rails-console = ''docker exec -it $(docker ps -q -f name=showcase_web | head -n 1) bash -c "cd /app && bundle exec rails console"'';
      };
    };
  };

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

  programs.home-manager.enable = true;
}
