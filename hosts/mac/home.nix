# Home Manager configuration for macOS (Darwin)
# Satellite workstation - MacBook Pro
#
# Touch ID for sudo is managed declaratively in hosts/mac/default.nix
# via security.pam.services.sudo_local (touchIdAuth + reattach for tmux).
{
  config,
  pkgs,
  lib,
  inputs,
  hmStateVersion,
  ...
}: let
  kittyThemesDir = "${pkgs.kitty-themes}/share/kitty-themes/themes";

  kittyThemeSwitchScript = pkgs.writeShellScript "kitty-theme-switch" ''
    THEME_FILE="$HOME/.config/kitty/current-theme.conf"
    MODE=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")

    if [ "$MODE" = "Dark" ]; then
      NEW="${kittyThemesDir}/Catppuccin-Mocha.conf"
    else
      NEW="${kittyThemesDir}/Catppuccin-Latte.conf"
    fi

    # Only update (and reload) if the theme actually changed
    if ! diff -q "$NEW" "$THEME_FILE" > /dev/null 2>&1; then
      cp "$NEW" "$THEME_FILE"
      chmod 644 "$THEME_FILE"
      pkill -SIGUSR1 kitty 2>/dev/null || true
    fi
  '';
in {
  # Import shared shell configuration
  imports = [
    ../../users/felipe/home-modules/shell.nix
    ../../users/felipe/home-modules/git.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "felipe";
    homeDirectory = "/Users/felipe";
    stateVersion = hmStateVersion;

    # macOS-specific packages
    packages = with pkgs; [
      # Development (lightweight for satellite)
      nodejs_22
      python3
      rustup
      tmuxinator
      lazygit
      _1password-cli

      # CLI tools
      btop # System monitor
      carapace # Multi-shell completion generator
      bat
      ripgrep
      fd
      eza
      jq
      yq
      yazi

      # Editors
      zed-editor

      # Security - lightweight antivirus (company requirement)
      clamav
    ];

    # Add local bin to PATH
    sessionPath = [
      "$HOME/.local/bin"
    ];

    # Environment variables
    sessionVariables = {
      LANG = "en_US.UTF-8";
      TZ = "America/New_York"; # Fix atuin timestamp issues
      # Homebrew
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_AUTO_UPDATE = "1"; # We update via nix-darwin
    };
  };

  programs.home-manager.enable = true;

  # SSH configuration (completely overrides shell.nix SSH config for macOS)
  programs.ssh = {
    enable = true;
    matchBlocks = {
      # Default settings for all hosts (macOS native keychain)
      "*" = {
        identityFile = ["~/.ssh/id_ed25519"];
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
        extraOptions = {
          TCPKeepAlive = "yes";
          AddKeysToAgent = "yes";
          UseKeychain = "yes"; # Store passphrase in macOS Keychain
          # IdentityAgent is NOT set - use system SSH agent instead of 1Password
        };
      };
    };
  };

  # macOS-specific Zsh additions (extends shell.nix)
  programs.zsh = {
    initContent = ''
      # Homebrew path (M1 Mac)
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    shellAliases = {
      # Prevent zsh from interpreting # in flake paths as glob
      darwin-rebuild = "noglob darwin-rebuild";
      nix = lib.mkForce "noglob nix";

      # Darwin rebuild commands (override NixOS ones from shell.nix)
      rebuild = lib.mkForce "bash /Users/felipe/.dotfiles/system/scripts/rebuild";
      rebuild-test = lib.mkForce "darwin-rebuild build --flake /Users/felipe/.dotfiles#mac";
      rebuild-boot = lib.mkForce "bash /Users/felipe/.dotfiles/system/scripts/rebuild"; # Same as rebuild on macOS
      update-flake = lib.mkForce "nix flake update --flake /Users/felipe/.dotfiles/";

      # Use native macOS clipboard (override Linux xclip aliases)
      pbcopy = lib.mkForce "pbcopy";
      pbpaste = lib.mkForce "pbpaste";

      # macOS-specific config editing
      edit-config = lib.mkForce "nvim ~/.dotfiles/hosts/mac/home.nix";
      edit-home = lib.mkForce "nvim ~/.dotfiles/hosts/mac/home.nix";

      # Connect to main NixOS workstation
      ws = "ssh workstation";
      wst = "ssh workstation -t 'tmux new-session -A -s main'";

      # Quick Moonlight streaming access
      stream = "open -a Moonlight";

      # Toggle macOS dark/light mode (kitty follows automatically via launchd watcher)
      tt = "osascript -e 'tell app \"System Events\" to tell appearance preferences to set dark mode to not dark mode'";

      # macOS-specific utilities
      showfiles = "defaults write com.apple.finder AppleShowAllFiles YES; killall Finder";
      hidefiles = "defaults write com.apple.finder AppleShowAllFiles NO; killall Finder";
      flushdns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";

      # macOS development directory
      dev = "cd ~/Developer";

      # ClamAV - scan home directory (definitions in ~/.clamav)
      scan = "clamscan --database=$HOME/.clamav -r --bell -i $HOME";

      # Aerospace workspace startup
      workspace-start = "~/.dotfiles/system/scripts/workspace-startup";

      # Personal workspace startup (non-work)
      personal-workspace = "~/.dotfiles/system/scripts/personal-workspace";

      # Tmux automation
      tmux-init = "~/.dotfiles/system/scripts/tmux-init.sh";
    };
  };

  # macOS-specific Kitty settings (extends home-terminal.nix config)
  programs.kitty = {
    enable = true;
    # Theme is managed dynamically by kitty-theme-watcher launchd agent
    extraConfig = "include ~/.config/kitty/current-theme.conf";

    # Enable shell integration (prompt jumping, better scrollback, etc.)
    shellIntegration.enableZshIntegration = true;

    settings = {
      # Font configuration
      font_family = "JetBrainsMono Nerd Font";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      # macOS specific
      macos_option_as_alt = true;
      macos_quit_when_last_window_closed = false;
      macos_thicken_font = "0.25";
      hide_window_decorations = "titlebar-only";

      # Override for Mac
      font_size = 14.3;
      background_opacity = "1.0";

      # Enable Touch ID for sudo in tmux
      macos_custom_beam_cursor = false;

      # Cursor — beam is easier to spot than block
      cursor_shape = "beam";
      cursor_blink_interval = 0;

      # Scrollback
      scrollback_lines = 10000;

      # URL handling
      url_style = "curly";
      open_url_with = "default";
      detect_urls = "yes";
      url_prefixes = "http https file ftp gemini irc gopher mailto news git";

      # Tab bar — powerline matches tmux separators
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";

      # Window behaviour
      window_padding_width = 8;
      remember_window_size = "yes";
      confirm_os_window_close = 0;
      focus_follows_mouse = "yes";
      copy_on_select = "yes";
    };

    keybindings = {
      # Pass Ctrl-Space through to tmux (tmux prefix)
      "ctrl+space" = "send_text all \\x00";

      # macOS-specific keybindings (Cmd instead of Ctrl)
      "cmd+t" = "new_tab";
      "cmd+w" = "close_tab";
      "cmd+1" = "send_text all \\x1b1";
      "cmd+2" = "send_text all \\x1b2";
      "cmd+3" = "send_text all \\x1b3";
      "cmd+4" = "send_text all \\x1b4";
      "cmd+5" = "send_text all \\x1b5";
      "cmd+6" = "send_text all \\x1b6";
      "cmd+7" = "send_text all \\x1b7";
      "cmd+8" = "send_text all \\x1b8";
      "cmd+9" = "send_text all \\x1b9";
      "cmd+shift+enter" = "new_window";
      "cmd+]" = "next_window";
      "cmd+[" = "previous_window";
    };
  };

  # Yazi file manager (shell.nix has configs, need to enable program)
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # Direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true; # Better nix integration
  };

  # Delta - beautiful git diffs with syntax highlighting
  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "Catppuccin Mocha";
      plus-style = "syntax #2a363b";
      minus-style = "syntax #3b2c2e";
      plus-emph-style = "syntax #3b5249";
      minus-emph-style = "syntax #6b3639";
      line-numbers-plus-style = "#a6e3a1";
      line-numbers-minus-style = "#f38ba8";
      hunk-header-style = "file line-number syntax";
    };
  };

  # Zoxide (smart cd replacement)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Neovim Lua configuration from dotfiles repo
  # Use an out-of-store symlink so the config is editable without rebuilding.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/nvim";

  # Zed editor configuration
  xdg.configFile."zed/settings.json".text = ''
    {
      "icon_theme": "Warm Charmed Icons",
      "theme": "Aura Dark",
      "theme_overrides": {
        "Aura Dark": {
          "editor.document_highlight.read_background": "#00000000",
          "editor.document_highlight.write_background": "#00000000",
          "border.variant": "#15141C",
          "border": "#15141C",
          "title_bar.background": "#15141C",
          "panel.background": "#15141C",
          "panel.focused_border": "#4E466E",
          "players": [
            {
              "cursor": "#BD9DFF"
            }
          ],
          "syntax": {
            "comment": {
              "font_style": "italic"
            },
            "comment.doc": {
              "font_style": "italic"
            }
          }
        }
      },
      "title_bar": {
        "show_onboarding_banner": false,
        "show_project_items": false,
        "show_branch_name": false,
        "show_user_menu": false
      },
      "tab_bar": {
        "show": false
      },
      "toolbar": {
        "quick_actions": false
      },
      "status_bar": {
        "experimental.show": false
      },
      "project_panel": {
        "dock": "right",
        "default_width": 400,
        "hide_root": true,
        "auto_fold_dirs": false,
        "starts_open": false,
        "git_status": false,
        "sticky_scroll": false,
        "scrollbar": {
          "show": "never"
        },
        "indent_guides": {
          "show": "never"
        }
      },
      "outline_panel": {
        "default_width": 300,
        "indent_guides": {
          "show": "never"
        }
      },
      "file_finder": {
        "modal_max_width": "large"
      },
      "scrollbar": {
        "show": "never"
      },
      "gutter": {
        "min_line_number_digits": 0,
        "folds": false,
        "runnables": false
      },
      "indent_guides": {
        "enabled": false
      },
      "ui_font_family": "Dank Mono",
      "ui_font_size": 20,
      "buffer_font_family": "Dank Mono",
      "buffer_font_size": 20,
      "buffer_line_height": {
        "custom": 2
      },
      "agent_buffer_font_size": 20,
      "vim_mode": true,
      "multi_cursor_modifier": "cmd_or_ctrl",
      "cursor_shape": "block",
      "cursor_blink": false,
      "selection_highlight": false,
      "drag_and_drop_selection": {
        "enabled": false
      },
      "seed_search_query_from_cursor": "never",
      "current_line_highlight": "none",
      "show_whitespaces": "none",
      "tab_size": 2,
      "auto_indent": false,
      "auto_indent_on_paste": false,
      "show_completions_on_input": false,
      "show_completion_documentation": false,
      "inline_code_actions": false,
      "lsp_document_colors": "none",
      "hover_popover_enabled": false,
      "format_on_save": "off",
      "autosave": {
        "after_delay": {
          "milliseconds": 1000
        }
      },
      "auto_update": false,
      "extend_comment_on_newline": false,
      "horizontal_scroll_margin": 1,
      "vertical_scroll_margin": 1,
      "when_closing_with_no_tabs": "keep_window_open",
      "close_on_file_delete": true,
      "restore_on_file_reopen": false,
      "restore_on_startup": "empty_tab",
      "session": {
        "restore_unsaved_buffers": false
      },
      "git": {
        "git_gutter": "hide",
        "inline_blame": {
          "enabled": false
        }
      },
      "centered_layout": {
        "right_padding": 0.15,
        "left_padding": 0.15
      }
    }
  '';

  # JankyBorders configuration - window border highlighting
  home.file.".config/borders/bordersrc".text = ''
    #!/bin/bash
    # JankyBorders config - Catppuccin Mocha colors
    borders active_color=0xffcba6f7 \
            inactive_color=0xff45475a \
            width=4.0 \
            hidpi=on \
            style=round
  '';

  # Aerospace tiling WM configuration (Hyprland-style)
  home.file.".aerospace.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/export/aerospace.toml";

  # Tmuxinator configurations
  xdg.configFile."tmuxinator/personal.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/export/tmuxinator/personal.yml";

  # FZF with Catppuccin colors
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.fzf.defaultOptions = [
    "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
    "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
    "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
  ];

  # Atuin - Better shell history with cloud sync
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Sync disabled until `atuin login` is run
      auto_sync = false;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh"; # Official server (or self-host)

      # Search behavior
      search_mode = "fuzzy"; # fuzzy, prefix, fulltext, skim
      filter_mode = "global"; # global, host, session, directory
      filter_mode_shell_up_key_binding = "global"; # Up arrow searches all history, not just current session

      # Key behavior — false lets you edit the selected command before running
      enter_accept = false;

      # UI settings
      style = "compact";
      inline_height = 12;
      show_preview = true;
      show_help = false; # Hide help bar for cleaner look
      show_tabs = true; # Show search mode tabs

      # Performance
      update_snapshots = true; # Keep command snapshots updated
      common_prefix = ["sudo"]; # Strip common prefixes for better search
      common_subcommands = ["cargo" "docker" "git" "kubectl" "nix"];

      # History settings - only filter truly useless commands
      history_filter = [
        "^exit$"
        "^clear$"
      ];

      # Store additional context
      store_failed = true; # Store commands that failed (useful for debugging)
      secrets_filter = true; # Filter out secrets from history
    };
  };

  # Set initial kitty theme on rebuild based on current system appearance
  home.activation.kittyTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${kittyThemeSwitchScript}
  '';

  # Switch macOS appearance based on power source: dark on battery, unchanged on AC
  launchd.agents.power-theme-watcher = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          ON_BATTERY=$(pmset -g ps | grep -c "Battery Power" || true)
          DARK_MODE=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
          if [ "$ON_BATTERY" -gt 0 ] && [ "$DARK_MODE" != "Dark" ]; then
            osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
          fi
        ''
      ];
      StartInterval = 10;
      RunAtLoad = true;
      StandardOutPath = "/tmp/power-theme-watcher.log";
      StandardErrorPath = "/tmp/power-theme-watcher.log";
    };
  };

  # Switch to dark mode at 4:30 PM daily
  launchd.agents.dark-mode-evening = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          DARK_MODE=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
          if [ "$DARK_MODE" != "Dark" ]; then
            osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
          fi
        ''
      ];
      StartCalendarInterval = [
        {
          Hour = 16;
          Minute = 30;
        }
      ];
      StandardOutPath = "/tmp/dark-mode-evening.log";
      StandardErrorPath = "/tmp/dark-mode-evening.log";
    };
  };

  # Watch for macOS appearance changes and update kitty theme automatically
  launchd.agents.kitty-theme-watcher = {
    enable = true;
    config = {
      ProgramArguments = ["${kittyThemeSwitchScript}"];
      StartInterval = 5;
      RunAtLoad = true;
      StandardOutPath = "/tmp/kitty-theme-watcher.log";
      StandardErrorPath = "/tmp/kitty-theme-watcher.log";
    };
  };

  # ClamAV - daily virus definition update
  launchd.agents.freshclam = {
    enable = true;
    config = {
      ProgramArguments = ["${pkgs.clamav}/bin/freshclam" "--datadir=${config.home.homeDirectory}/.clamav"];
      StartCalendarInterval = [
        {
          Hour = 3;
          Minute = 0;
        }
      ]; # Daily at 3 AM
      RunAtLoad = true;
      StandardOutPath = "/tmp/freshclam.log";
      StandardErrorPath = "/tmp/freshclam.log";
    };
  };

  # rclone - Auto-mount Google Drive on login
  # Uses official rclone binary (/usr/local/bin/rclone) — not Homebrew's (no FUSE support)
  # Files are downloaded on-demand; cache capped at 5GB in ~/.cache/rclone/
  launchd.agents.rclone-gdrive = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "mkdir -p ${config.home.homeDirectory}/GoogleDrive && /usr/local/bin/rclone mount gdrive-remote: ${config.home.homeDirectory}/GoogleDrive --vfs-cache-mode full --vfs-cache-max-size 5G --volname 'Google Drive'"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/rclone-gdrive.log";
      StandardErrorPath = "/tmp/rclone-gdrive.log";
    };
  };

  # Carapace - Multi-shell completion generator
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  # macOS-specific git user name override
  programs.git.settings.user.name = "lftpadilla";

  # Karabiner-Elements configuration
  # Managed via export/karabiner.json (symlinked, not copied — editable without rebuild)
  # Add complex/simple modifications there directly; Karabiner picks up changes live.
  home.file.".config/karabiner/karabiner.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/export/karabiner.json";
}
