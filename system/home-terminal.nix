{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../users/felipe/home-modules/shell.nix
  ];

  home.username = "felipe";
  home.stateVersion = "24.05";

  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Mocha"; # "One Half Light";  # "Catppuccin-Latte";
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
      shell = "${pkgs.tmux}/bin/tmux new-session -A -s main";
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

  programs.home-manager.enable = true;
}
