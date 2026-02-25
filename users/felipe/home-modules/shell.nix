{
  config,
  pkgs,
  lib,
  ...
}: {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      # Faster, XDG-aware completion cache
      completionInit = ''
        autoload -Uz compinit
        ZSH_COMPDUMP="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-''${HOST}-''${ZSH_VERSION}"
        mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
        compinit -C -d "$ZSH_COMPDUMP"
      '';
      initContent = ''
        # Terminal fallback for kitty terminfo mismatches
        if [[ $TERM == "xterm-kitty" && ! -f "/usr/share/terminfo/x/xterm-kitty" ]]; then
          export TERM=xterm-256color
        fi

        # Zsh quality-of-life options
        setopt AUTO_CD CORRECT INTERACTIVE_COMMENTS EXTENDED_GLOB
        setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY
        unsetopt BEEP

        # Deduplicate PATH entries
        typeset -U path PATH

        # Prevent terminal XON/XOFF (Ctrl-S/Ctrl-Q) from freezing input
        # and ensure no idle auto-logout in interactive shells
        if [[ -o interactive ]]; then
          stty -ixon -ixoff 2>/dev/null || true
          unset TMOUT
        fi

        # Double-ESC to toggle sudo prefix (replaces oh-my-zsh sudo plugin)
        sudo-command-line() {
          [[ -z $BUFFER ]] && zle up-history
          if [[ $BUFFER == sudo\ * ]]; then
            LBUFFER="''${LBUFFER#sudo }"
          else
            LBUFFER="sudo $LBUFFER"
          fi
        }
        zle -N sudo-command-line
        bindkey "\e\e" sudo-command-line

        # Prevent shells/themes from overriding terminal/tab title
        export DISABLE_AUTO_TITLE="true"

        # Auto-attach to the shared tmux session when logging in via SSH.
        # (Kitty already starts tmux via its `shell` setting.)
        # if [[ -o interactive && -n "''${SSH_CONNECTION-}''${SSH_TTY-}" && -z "''${TMUX-}" ]]; then
        #   if command -v tmux >/dev/null 2>&1; then
        #     exec tmux new-session -A -s main
        #   fi
        # fi
      '';
      history = {
        size = 100000;
        save = 100000;
        share = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
        path = "${config.xdg.stateHome}/zsh/history";
      };
      shellAliases =
        {
          # File operations - eza with icons and git status
          ls = "eza --icons --group-directories-first";
          ll = "eza -l --icons --git --group-directories-first";
          la = "eza -a --icons --group-directories-first";
          lla = "eza -la --icons --git --group-directories-first";
          lt = "eza -l --icons --git --tree --level=2";
          tree = "eza --tree --icons --group-directories-first";
          y = "yazi";
          r = "ranger";

          # System operations (cross-platform safe)
          htop = "btop";
          top = "btop";

          # Git shortcuts
          g = "git";
          ga = "git add";
          gaa = "git add --all";
          gc = "git commit -v";
          "gc!" = "git commit -v --amend";
          gca = "git commit -v -a";
          "gca!" = "git commit -v -a --amend";
          gco = "git checkout";
          gcb = "git checkout -b";
          gst = "git status";
          gp = "git push";
          gl = "git pull";
          gd = "git diff";
          gdc = "git diff --cached";
          gb = "git branch";
          gm = "git merge";
          grb = "git rebase";
          glog = "git log --oneline --graph";
          lg = "lazygit";

          # Nix
          nix = "noglob nix";

          # Network and system info
          ports = "ss -tuln";
          myip = "curl -s ipinfo.io/ip";
          weather = "curl -s wttr.in";

          # Quick editing
          v = "nvim";
          vim = "nvim";

          # Docker shortcuts
          d = "docker";
          dc = "docker compose";
          dps = "docker ps";
          di = "docker images";

          # Quick directories
          dl = "cd ~/Downloads";
          docs = "cd ~/Documents";
          dot = "cd ~/.dotfiles";

          # Miscellaneous
          reload = "source ~/.zshrc";
          path = "echo $PATH | tr ':' '\n'";
          h = "history | grep";
          mkdir = "mkdir -p";
          # Trash-based deletion (trash-cli)
          del = "trash";
          emptytrash = "trash-empty";
          restoretrash = "trash-restore";

          # AI Tools
          gemini = "export GOOGLE_CLOUD_PROJECT=\"wired-effort-416222\" && npx -y https://github.com/google-gemini/gemini-cli";
          claudia = "npx -y @anthropic-ai/claude-code@latest";
          qwen = "npx -y @qwen-code/qwen-code@latest";
          ccr-code = "npx -y @musistudio/claude-code-router start";
          ccr-ui = "npx -y @musistudio/claude-code-router ui";
          claude-code-temp = "npx -y claude-code-templates@latest";

          # Claude Code with separate config directories
          claude-work = "CLAUDE_CONFIG_DIR=~/.claude-work claude";
          claude-personal = "CLAUDE_CONFIG_DIR=~/.claude-personal claude";

          # System monitoring (cross-platform)
          sysmon = "btop";
          monitor = "btop";

          # Work launcher
          work = "work";
        }
        // lib.optionalAttrs pkgs.stdenv.isLinux {
          # Clipboard (Linux only - macOS has native pbcopy/pbpaste)
          pbcopy = "xclip -selection clipboard";
          pbpaste = "xclip -selection clipboard -o";

          # NixOS system management
          nixos-rebuild = "noglob nixos-rebuild";
          rebuild = "bash $HOME/.dotfiles/system/scripts/rebuild";
          rebuild-proxmox = "bash $HOME/.dotfiles/system/scripts/rebuild nixos-proxmox";
          rebuild-test = "sudo nixos-rebuild test --flake '/home/felipe/.dotfiles#default'";
          rebuild-boot = "sudo nixos-rebuild boot --flake '/home/felipe/.dotfiles#default'";
          update-flake = "nix flake update --flake /home/felipe/.dotfiles/";
          rebuild-cloud = "NIX_SSHOPTS='-i /home/felipe/.ssh/nixos-cloud-desktop-key.pem -o IdentitiesOnly=yes -o StrictHostKeyChecking=no' nixos-rebuild switch --flake \"$HOME/.dotfiles/deploy/nixos-cloud#nixos-installer\" --target-host root@nixos-cloud --build-host root@nixos-cloud";
          ec2on = "AWS_PROFILE=nixos-deployer aws ec2 start-instances --instance-ids i-08796d84d584d092f";
          ec2off = "AWS_PROFILE=nixos-deployer aws ec2 stop-instances --instance-ids i-08796d84d584d092f";

          # Network (Linux)
          ip = "ip -color=auto";
          tailscaled-up-no-routes = "sudo systemctl start tailscaled && sudo tailscale up --advertise-exit-node --accept-dns=false";
          tailscaled-up-routes = "sudo systemctl start tailscaled && sudo tailscale up --advertise-exit-node --accept-dns=false --accept-routes";
          tailscaled-up = "sudo systemctl start tailscaled && sudo tailscale up --advertise-exit-node --accept-dns=false --accept-routes";

          # Config editing (Linux paths)
          edit-config = "nvim ~/.dotfiles/hosts/main/configuration.nix";
          edit-home = "nvim ~/.dotfiles/system/home.nix";

          # Linux application shortcuts
          web = "qutebrowser";
          fm = "dolphin";

          # System monitoring (Linux-specific)
          sysinfo = "neofetch";
          temps = "sensors";
          processes = "procs --tree";
          disk-usage = "duf";
          disk-health = "sudo smartctl -a";
          network-usage = "bandwhich";
          io-monitor = "sudo iotop";

          # Theme switching (GNOME)
          dark-theme = "~/.dotfiles/system/scripts/dark-theme";
          light-theme = "~/.dotfiles/system/scripts/light-theme";
          tt = "~/.dotfiles/system/scripts/toggle-theme";

          # Power profile switching (Linux)
          power-saver = "powerprofilesctl set power-saver";
          balanced = "powerprofilesctl set balanced";
          performance = "powerprofilesctl set performance";
          power-status = "powerprofilesctl get";
          power-list = "powerprofilesctl list";

          # Systemd services
          sc = "sudo systemctl";
          jc = "sudo journalctl";
          ss = "systemctl --user";
          js = "journalctl --user";
          restart = "sudo systemctl restart";
          stop = "sudo systemctl stop";
          start = "sudo systemctl start";
          status = "sudo systemctl status";
        };
    };

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        username = {
          style_user = "white";
          style_root = "white";
          format = "[$user]($style) ";
          disabled = false;
          show_always = true;
        };
        hostname = {
          ssh_only = false;
          format = "@ [$hostname](bold yellow) ";
          disabled = false;
        };
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };
        nix_shell = {
          symbol = " ";
          style = "bold blue";
          format = "via [$symbol$state( \($name\))]($style) ";
        };
        cmd_duration = {
          min_time = 2000;
          format = "took [$duration](bold yellow)";
        };
        terraform = {
          format = "via [$symbol$workspace]($style) ";
          symbol = "💠 ";
        };
        directory = {
          home_symbol = "󰋞 ~";
          read_only_style = "197";
          read_only = "  ";
          format = "at [$path]($style)[$read_only]($read_only_style) ";
        };
        git_branch = {
          symbol = " ";
          format = "via [$symbol$branch]($style) ";
          style = "bold green";
        };
        git_status = {
          format = "[\($all_status$ahead_behind\)]($style) ";
          style = "bold green";
          conflicted = "🏳";
          up_to_date = " ";
          untracked = " ";
          ahead = "⇡\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          behind = "⇣\${count}";
          stashed = " ";
          modified = " ";
          staged = "[++($count)](green)";
          renamed = "襁 ";
          deleted = " ";
        };
        python = {
          symbol = " ";
          format = "via [$symbol$pyenv_prefix($version )(\($virtualenv\) )]($style)";
        };
      };
    };

    tmux = {
      enable = true;
      plugins = with pkgs.tmuxPlugins; [
        sensible
        # Theme
        catppuccin
        # Utilities
        prefix-highlight
        yank
        resurrect
        continuum
        battery
        cpu
      ];
      extraConfig = ''
        # Prefix: Backtick (`) - primary, Ctrl-Space and Ctrl-b - secondary
        set -g prefix `
        set -g prefix2 C-Space
        set -ga prefix2 C-b
        bind ` send-prefix
        bind C-Space send-prefix
        bind C-b send-prefix

        # Better defaults
        # Advertise tmux-256color and truecolor capabilities (tmux ≥ 3.3)
        set -g default-terminal "tmux-256color"
        set -as terminal-features ",xterm-256color:RGB,screen-256color:RGB,tmux-256color:RGB,alacritty:RGB,xterm-kitty:RGB,foot:RGB"
        # Hint apps to use truecolor inside tmux
        set-environment -g COLORTERM truecolor
        set -g mouse on
        set -g history-limit 50000
        # Start windows and panes at 1, not 0
        set -g base-index 1
        set -g pane-base-index 1
        set-window-option -g pane-base-index 1
        set-hook -g session-created "if-shell \"[ '#{session_name}' = '0' ]\" \"rename-session 1\""
        # Renumber windows when one is closed
        set-option -g renumber-windows on
        # Automatically name windows after the current command; ignore program renames
        set -g automatic-rename on
        set -g automatic-rename-format "#{pane_current_command}"
        set -g allow-rename off
        set -g set-titles on
        # Show window name in terminal/tab title
        set -g set-titles-string "#W"

        # Remove delays
        set -s escape-time 0
        set -g repeat-time 600
        set -g focus-events on

        # Vi mode
        set-window-option -g mode-keys vi
         # Integrate copy with system clipboard; prefer wl-copy, fallback to xclip
         set -s set-clipboard on
         bind-key -T copy-mode-vi 'v' send -X begin-selection
         bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel 'wl-copy 2>/dev/null || xclip -selection clipboard -in 2>/dev/null || pbcopy'
         bind-key -T copy-mode-vi 'r' send -X rectangle-toggle
         # Copy on mouse selection (drag release) for both key tables
         bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel 'wl-copy 2>/dev/null || xclip -selection clipboard -in 2>/dev/null || pbcopy'
         bind-key -T copy-mode MouseDragEnd1Pane send -X copy-pipe-and-cancel 'wl-copy 2>/dev/null || xclip -selection clipboard -in 2>/dev/null || pbcopy'

        # Keyboard shortcuts (vim-style)
        # Move between panes with prefix + h/j/k/l
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
         # Ctrl-h/j/k/l without prefix moves between panes, but won't steal keys in TUIs.
         bind -n C-h if-shell "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +([^ ]+/)?(n?vim|vim|view|vimdiff|nvimdiff|fzf|yazi|ranger|lf)$'" 'send-keys C-h' 'select-pane -L'
         bind -n C-j if-shell "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +([^ ]+/)?(n?vim|vim|view|vimdiff|nvimdiff|fzf|yazi|ranger|lf)$'" 'send-keys C-j' 'select-pane -D'
         bind -n C-k if-shell "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +([^ ]+/)?(n?vim|vim|view|vimdiff|nvimdiff|fzf|yazi|ranger|lf)$'" 'send-keys C-k' 'select-pane -U'
         bind -n C-l if-shell "ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +([^ ]+/)?(n?vim|vim|view|vimdiff|nvimdiff|fzf|yazi|ranger|lf)$'" 'send-keys C-l' 'select-pane -R'

        # Window splitting (defaults + easier alternatives)
        # Defaults (widely documented)
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        # Easier, shift-less alternatives
        bind - split-window -v -c "#{pane_current_path}"
        bind \\ split-window -h -c "#{pane_current_path}"
        # Keep existing as optional
        bind | split-window -h -c "#{pane_current_path}"

         # Show pane headers with index, command, and path
         set -g pane-border-status top
         set -g pane-border-format " #{pane_index} #{pane_current_command} #{=-40:pane_current_path}"

        # Pane resizing (shift variants kept as an alternative)
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # Window navigation
        bind -r C-h select-window -t :-
        bind -r C-l select-window -t :+
        # Alt/Cmd + number to switch windows (like browser tabs)
        bind -n M-1 select-window -t 1
        bind -n M-2 select-window -t 2
        bind -n M-3 select-window -t 3
        bind -n M-4 select-window -t 4
        bind -n M-5 select-window -t 5
        bind -n M-6 select-window -t 6
        bind -n M-7 select-window -t 7
        bind -n M-8 select-window -t 8
        bind -n M-9 select-window -t 9

        # Session management
        # Click session name in status-left to open session switcher
        bind -n MouseDown1StatusLeft choose-tree -Zs
        bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
        bind x kill-pane
        bind X kill-window
        bind c new-window -c "#{pane_current_path}"

         # Quick access to common commands
         bind g new-window -n "git" -c "#{pane_current_path}" "git status"
         bind t new-window -n "htop" "btop"
         bind y new-window -n "yazi" -c "#{pane_current_path}" "yazi"
         # Popups (tmux >= 3.2)
         bind T display-popup -E -T "btop" -d "#{pane_current_path}" -w 90% -h 90% "btop"
         bind Y display-popup -E -T "yazi" -d "#{pane_current_path}" -w 90% -h 90% "yazi"

        # URLs: pick from scrollback with fzf and open via xdg-open
        bind u run-shell -b "~/.local/bin/fzf-tmux-url"

        # FZF tmux switcher bindings (custom scripts - alternative to tmux-fzf plugin)
         bind f run-shell -b "~/.local/bin/tmux-fzf-switch all"
         bind S run-shell -b "~/.local/bin/tmux-fzf-switch sessions"
         bind W run-shell -b "~/.local/bin/tmux-fzf-switch windows"
         bind P run-shell -b "~/.local/bin/tmux-fzf-switch panes"
         # Sessionizer: pick a directory and jump/create a session (alternative: prefix+o for sessionx)
         bind C-f run-shell -b "~/.local/bin/tmux-sessionizer"

        # Kubernetes context indicator appended to status-right
        # set -ga status-right " #(~/.local/bin/tmux-kube)"

         # ============================================
         # CUSTOM THEME - Clean Modern Design
         # ============================================
         # Catppuccin Mocha palette:
         # base: #1e1e2e | surface0: #313244 | surface1: #45475a
         # text: #cdd6f4 | subtext: #a6adc8 | overlay: #6c7086
         # blue: #89b4fa | green: #a6e3a1 | peach: #fab387
         # mauve: #cba6f7 | pink: #f5c2e7 | teal: #94e2d5

         set -g status-position top
         set -g status-interval 5
         set -g status-justify centre

         # Status bar base - transparent feel with margins
         set -g status-style "bg=#1e1e2e"
         set -g status-left-length 100
         set -g status-right-length 100

         # Left: Session with icon and rounded pill
         set -g status-left "#[fg=#1e1e2e,bg=#cba6f7,bold]  #S #[fg=#cba6f7,bg=#1e1e2e]   "

         # Right: Directory + Git + Time with pills
         set -g status-right "#[fg=#313244,bg=#1e1e2e]#[fg=#cdd6f4,bg=#313244]  #{b:pane_current_path} #[fg=#1e1e2e,bg=#313244]#[fg=#313244,bg=#1e1e2e] #[fg=#45475a,bg=#1e1e2e]#[fg=#a6adc8,bg=#45475a]  %H:%M #[fg=#89b4fa,bg=#45475a]#[fg=#1e1e2e,bg=#89b4fa]  %d %b #[fg=#89b4fa,bg=#1e1e2e]"

         # Window status - clean pills with spacing
         set -g window-status-separator "  "
         set -g window-status-format "#[fg=#313244,bg=#1e1e2e]#[fg=#6c7086,bg=#313244] #I  #W #[fg=#313244,bg=#1e1e2e]"
         set -g window-status-current-format "#[fg=#a6e3a1,bg=#1e1e2e]#[fg=#1e1e2e,bg=#a6e3a1,bold] #I  #W#{?window_zoomed_flag,  ,} #[fg=#a6e3a1,bg=#1e1e2e]"

         # Pane borders - subtle
         set -g pane-border-style "fg=#313244"
         set -g pane-active-border-style "fg=#cba6f7"
         set -g pane-border-lines "single"

         # Message and mode styling
         set -g message-style "fg=#cdd6f4,bg=#313244"
         set -g mode-style "fg=#1e1e2e,bg=#f5c2e7"

         # Clock
         set -g clock-mode-colour "#89b4fa"
         set -g clock-mode-style 24

         # Pane number display
         set -g display-panes-active-colour "#a6e3a1"
         set -g display-panes-colour "#6c7086"


        # Prefix/copy/sync indicators styling (tmux-prefix-highlight)
        set -g @prefix_highlight_fg "#1e1e2e"
        set -g @prefix_highlight_bg "#fab387"
        set -g @prefix_highlight_show_copy_mode "on"
        set -g @prefix_highlight_copy_mode_attr "fg=#1e1e2e,bg=#f5c2e7,bold"
        set -g @prefix_highlight_show_sync_mode "on"
        set -g @prefix_highlight_sync_mode_attr "fg=#1e1e2e,bg=#f38ba8,bold"

        # Git autofetch on focus (lightweight)
        set-hook -ga pane-focus-in 'run-shell -b "~/.local/bin/tmux-git-autofetch"'

        # Autoreload tmux config when it changes
        set-hook -g client-attached 'run-shell -b "~/.local/bin/tmux-autoreload"'
        set-hook -ga session-created 'run-shell -b "~/.local/bin/tmux-autoreload"'

        # Mighty scroll in copy-mode (bigger steps)
        bind-key -T copy-mode-vi J send -X -N 10 scroll-down
        bind-key -T copy-mode-vi K send -X -N 10 scroll-up
        bind-key -T copy-mode-vi C-d send -X -N 20 scroll-down
        bind-key -T copy-mode-vi C-u send -X -N 20 scroll-up

        # Menus (built-in display-menu)
        bind m run-shell -b "~/.local/bin/tmux-menus"

        # Sidebar toggle (yazi/ranger) - alternative: prefix+F for floax
        bind b run-shell -b "~/.local/bin/tmux-sidebar toggle"
        bind B run-shell -b "~/.local/bin/tmux-sidebar open 40"

        # Extract items (URLs, emails, SHAs, paths) from scrollback (alternative: prefix+Space for thumbs)
        bind e run-shell -b "~/.local/bin/tmux-extracto"

        # Session restore
        set -g @continuum-restore 'on'
        set -g @continuum-save-interval '15'

        # ============================================
        # TPM PLUGINS (installed via Tmux Plugin Manager)
        # ============================================

        # TPM Plugin list
        set -g @plugin 'tmux-plugins/tpm'
        set -g @plugin 'omerxx/tmux-sessionx'
        set -g @plugin 'fcsonline/tmux-thumbs'
        set -g @plugin 'omerxx/tmux-floax'
        set -g @plugin 'sainnhe/tmux-fzf'

        # ============================================
        # PLUGIN CONFIGURATIONS
        # ============================================

        # tmux-sessionx: Advanced session manager
        set -g @sessionx-bind 'o'
        set -g @sessionx-window-height '85%'
        set -g @sessionx-window-width '75%'
        set -g @sessionx-zoxide-mode 'on'
        set -g @sessionx-filter-current 'false'
        set -g @sessionx-preview-enabled 'true'
        set -g @sessionx-custom-paths-subdirectories 'false'

        # tmux-floax: Floating terminal
        set -g @floax-bind 'F'
        set -g @floax-width '80%'
        set -g @floax-height '80%'
        set -g @floax-border-color 'magenta'
        set -g @floax-text-color 'blue'
        set -g @floax-change-path 'true'

        # tmux-thumbs: Copy/paste with keyboard hints
        set -g @thumbs-key 'Space'
        set -g @thumbs-command 'echo -n {} | (wl-copy 2>/dev/null || xclip -selection clipboard -in 2>/dev/null || pbcopy)'
        set -g @thumbs-upcase-command 'echo -n {} | xdg-open'

        # tmux-fzf: FZF integration for tmux
        TMUX_FZF_LAUNCH_KEY="C-f"
        TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"

        # Initialize TPM (keep this at the very bottom)
        run '~/.tmux/plugins/tpm/tpm'

        # Show neofetch on session creation
        set-hook -g session-created 'run-shell "${pkgs.neofetch}/bin/neofetch"'
      '';
    };
  };

  # Manage SSH config via Home Manager: keep connections alive and
  # preserve existing host entries.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        identityFile = ["~/.ssh/id_ed25519"];
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
        extraOptions = {
          TCPKeepAlive = "yes";
          AddKeysToAgent = "yes";
          IdentityAgent = "~/.1password/agent.sock";
        };
      };
      "ec2-swarm" = {
        hostname = "23.23.253.44";
        user = "ubuntu";
        identityFile = ["~/.ssh/showcase-staging.pem"];
      };
    };
  };

  home.file.".config/yazi/keymap.toml".text = ''
    [manager]
    prepend_keymap = [
      { on = ["<C-h>"], run = "toggle_hidden", desc = "Toggle hidden files" },
    ]
  '';

  home.file.".config/yazi/yazi.toml".text = ''
    # File manager settings
    [manager]
    show_hidden = true          # Show hidden files by default
    show_symlink = true         # Show symlink targets
    sort_by = "natural"         # Natural sort order
    sort_sensitive = false      # Case-insensitive sorting
    sort_reverse = false        # Regular sort order
    sort_dir_first = true      # Show directories first
    linemode = "size"          # Show file sizes by default

    # Layout configuration
    [preview]
    tab_size = 2               # Tab width in preview
    max_width = 600           # Maximum preview width
    max_height = 900         # Maximum preview height
    cache_size = 100        # Preview cache size (MB)

    # File preview settings
    [opener]
    edit = [
      { run = 'nvim "$@"', block = true, desc = "Edit in Neovim" },
      { run = '$EDITOR "$@"', block = true, desc = "Edit in default editor" }
    ]

    # Archive preview settings
    archive = [
      { run = 'unar "$1"', desc = "Extract archive" }
    ]

    # Image preview settings
    image = [
      { run = 'imv "$@"', desc = "View image" }
    ]

    # Media preview settings
    video = [
      { run = 'mpv "$@"', desc = "Play video" }
    ]
    audio = [
      { run = 'mpv "$@"', desc = "Play audio" }
    ]

    # Document preview settings
    pdf = [
      { run = 'zathura "$@"', desc = "View PDF" }
    ]

    # Web content settings
    html = [
      { run = 'xdg-open "$@"', desc = "Open in browser" }
    ]
  '';

  home.file.".config/yazi/theme.toml".text = ''
    # Theme configuration
    [manager]
    # Highlight colors
    fg_hidden = { fg = "gray" }     # Hidden files
    fg_link = { fg = "cyan" }       # Symlinks
    fg_dir = { fg = "blue" }        # Directories
    fg_exec = { fg = "green" }      # Executables

    # Status line colors
    status_normal = { fg = "black", bg = "white" }
    status_error = { fg = "white", bg = "red" }
    status_job = { fg = "black", bg = "yellow" }

    # Border style
    border_symbol = "│"
    border_style = { fg = "gray" }
  '';

  # tmux-autoreload: watch config and source-file on change
  home.file.".local/bin/tmux-autoreload" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      conf="''${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
      [[ -f "$conf" ]] || conf="$HOME/.tmux.conf"
      [[ -f "$conf" ]] || exit 0

      # Prevent duplicate watchers per user+conf
      mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}"
      lock="''${XDG_CACHE_HOME:-$HOME/.cache}/tmux-autoreload-$(printf '%s' "$conf" | sha1sum | awk '{print $1}').pid"
      if [[ -f "$lock" ]]; then
        oldpid=$(cat "$lock" 2>/dev/null || true)
        if [[ -n "''${oldpid:-}" ]] && kill -0 "$oldpid" 2>/dev/null; then
          exit 0
        fi
      fi
      echo "$$" > "$lock"
      trap 'rm -f "$lock"' EXIT

      # Function to reload config
      reload() {
        tmux source-file "$conf" \; display-message "tmux.conf autoreloaded"
      }

      # Prefer inotify if available; fallback to polling
      if command -v inotifywait >/dev/null 2>&1; then
        # Quietly listen to writes/attrib changes
        while inotifywait -qq -e close_write,attrib,move,create "$(dirname "$conf")"; do
          # Only react if target file changed
          # shellcheck disable=SC2012
          if [[ -f "$conf" ]]; then
            reload || true
          fi
        done
      else
        last="$(date +%s)"
        _mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
        if [[ -f "$conf" ]]; then last=$(_mtime "$conf"); fi
        while sleep 2; do
          now=$(_mtime "$conf")
          if [[ "$now" != "$last" ]]; then
            last="$now"
            reload || true
          fi
        done
      fi
    '';
  };

  # Git autofetch for active pane repo (lightweight alternative to a plugin)
  home.file.".local/bin/tmux-git-autofetch" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      [[ "''${TMUX_GIT_AUTOFETCH:-1}" = 1 ]] || exit 0
      dir=$(tmux display -p -F '#{pane_current_path}')
      if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$dir")
        cache="''${XDG_CACHE_HOME:-$HOME/.cache}/tmux-git-autofetch"
        mkdir -p "$cache"
        key=$(printf '%s' "$top" | sha1sum | awk '{print $1}')
        stamp="$cache/$key.stamp"
        now=$(date +%s)
        interval="''${TMUX_GIT_AUTOFETCH_INTERVAL:-600}"
        last=0; [[ -f "$stamp" ]] && last=$(cat "$stamp" 2>/dev/null || echo 0)
        if [[ $((now - last)) -ge $interval ]]; then
          ( git -C "$top" fetch --all -p -q >/dev/null 2>&1 && echo "$now" > "$stamp" ) &
        fi
      fi
    '';
  };

  # Simple tmux menus using built-in display-menu
  home.file.".local/bin/tmux-menus" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      tmux display-menu -T "#[align=centre] TMUX Menu" \
        "New window" n "new-window -c '#{pane_current_path}'" \
        "Rename window" , "command-prompt -I '#W' 'rename-window %%'" \
        "-" "-" \
        "Split horizontal" h "split-window -h -c '#{pane_current_path}'" \
        "Split vertical" v "split-window -v -c '#{pane_current_path}'" \
        "Kill pane" x "kill-pane" \
        "-" "-" \
        "Git status (new win)" g "new-window -n git -c '#{pane_current_path}' 'git status'" \
        "Toggle sidebar" b "run-shell '~/.local/bin/tmux-sidebar toggle'" \
        "fzf switcher" f "run-shell '~/.local/bin/tmux-fzf-switch all'" \
        "Extract items" e "run-shell '~/.local/bin/tmux-extracto'" \
        "-" "-" \
        "Reload config" r "source-file ~/.config/tmux/tmux.conf \; display-message 'Reloaded!'" \
        "Detach" d "detach-client" \
        "Kill window" X "kill-window"
    '';
  };

  # Sidebar toggle for file manager (yazi/ranger/lf)
  home.file.".local/bin/tmux-sidebar" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      mode="''${1:-toggle}"
      width="''${2:-50%}"
      dir=$(tmux display -p -F '#{pane_current_path}')
      existing=$(tmux list-panes -F '#{pane_id}::#{pane_title}' | awk -F:: '$2=="SIDEBAR"{print $1; exit}')
      case "$mode" in
        toggle)
          if [[ -n "''${existing:-}" ]]; then tmux kill-pane -t "$existing"; exit 0; fi
          set -- open "$width" ;;
      esac
      if [[ "''${1:-}" = open ]]; then
        if [[ "$width" == *% ]]; then
          size="''${width%\%}"
          pid=$(tmux split-window -h -p "$size" -c "$dir" -P -F '#{pane_id}')
        else
          pid=$(tmux split-window -h -l "$width" -c "$dir" -P -F '#{pane_id}')
        fi
        tmux select-pane -T SIDEBAR -t "$pid"
        tmux send-keys -t "$pid" 'yazi || ranger || lf' C-m
        exit 0
      fi
      if [[ "''${1:-}" = close ]]; then
        [[ -n "''${existing:-}" ]] && tmux kill-pane -t "$existing"
      fi
    '';
  };

  # Extract items from scrollback and open or copy
  home.file.".local/bin/tmux-extracto" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      if ! HISTORY=$(tmux capture-pane -J -S -10000 -p 2>/dev/null); then
        tmux display-message "Unable to capture pane history"; exit 0; fi
      command -v fzf >/dev/null 2>&1 || { tmux display-message "fzf not installed"; exit 0; }

      urls=$(printf '%s\n' "$HISTORY" | grep -Eo 'https?://[^[:space:]]+' | sed -E 's/[)\]\.,;:!\?"]+$//' | sed 's/^/URL\t/')
      emails=$(printf '%s\n' "$HISTORY" | grep -Eo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | sed 's/^/EMAIL\t/')
      shas=$(printf '%s\n' "$HISTORY" | grep -Eo '\b[0-9a-f]{7,40}\b' | sed 's/^/SHA\t/')
      paths=$(printf '%s\n' "$HISTORY" | grep -Eo '(/[^[:space:]]+)' | sed 's/^/PATH\t/')

      items=$(printf '%s\n%s\n%s\n%s\n' "$urls" "$emails" "$shas" "$paths" | sed '/^$/d' | sort -u)
      [[ -z "$items" ]] && { tmux display-message "No items found"; exit 0; }

      sel=$(printf '%s\n' "$items" | fzf --height 40% --border --with-nth=1,2 --delimiter='\t' --prompt='Extracto> ' || true)
      [[ -z "$sel" ]] && exit 0
      type=$(printf '%s' "$sel" | awk -F '\t' '{print $1}')
      val=$(printf '%s' "$sel" | cut -f2-)

      case "$type" in
        URL)
          if command -v xdg-open >/dev/null 2>&1; then nohup xdg-open "$val" >/dev/null 2>&1 &
          elif command -v sensible-browser >/dev/null 2>&1; then nohup sensible-browser "$val" >/dev/null 2>&1 &
          elif command -v open >/dev/null 2>&1; then nohup open "$val" >/dev/null 2>&1 &
          else printf '%s' "$val" | wl-copy 2>/dev/null || printf '%s' "$val" | xclip -selection clipboard -in 2>/dev/null || true; fi
          ;;
        EMAIL|SHA|PATH)
          printf '%s' "$val" | wl-copy 2>/dev/null || printf '%s' "$val" | xclip -selection clipboard -in 2>/dev/null || true
          tmux display-message "Copied to clipboard"
          ;;
      esac
    '';
  };

  # fzf-tmux-url helper script
  home.file.".local/bin/fzf-tmux-url" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Capture up to 10000 lines from pane history, join wrapped lines
      if ! HISTORY=$(tmux capture-pane -J -S -10000 -p 2>/dev/null); then
        tmux display-message "Unable to capture pane history"
        exit 0
      fi

      # Extract URLs, trim common trailing punctuation, dedupe
      URLS=$(printf '%s\n' "$HISTORY" \
        | grep -Eo 'https?://[^[:space:]]+' \
        | sed -E 's/[)\]\.,;:!\?"]+$//' \
        | sort -u)

      if [[ -z "''${URLS}" ]]; then
        tmux display-message "No URLs found in scrollback"
        exit 0
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        tmux display-message "fzf not installed"
        exit 0
      fi

      # Pick one or more URLs
      SELECTION=$(printf '%s\n' "$URLS" | fzf --multi --height 40% --border --prompt='URLs> ' || true)
      if [[ -z "''${SELECTION}" ]]; then
        exit 0
      fi

      # Open each selected URL using best available opener
      while IFS= read -r url; do
        if command -v xdg-open >/dev/null 2>&1; then
          nohup xdg-open "$url" >/dev/null 2>&1 &
        elif command -v sensible-browser >/dev/null 2>&1; then
          nohup sensible-browser "$url" >/dev/null 2>&1 &
        elif command -v open >/dev/null 2>&1; then
          nohup open "$url" >/dev/null 2>&1 &
        else
          tmux display-message "No URL opener found for: $url"
        fi
      done <<< "$SELECTION"
    '';
  };

  # tmux-fzf-switch helper script (sessions/windows/panes)
  home.file.".local/bin/tmux-fzf-switch" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      mode="''${1:-all}"

      if ! command -v fzf >/dev/null 2>&1; then
        tmux display-message "fzf not installed"
        exit 0
      fi

      list_sessions() {
        tmux list-sessions -F '#{session_name}\tS\t#{session_windows} windows'
      }

      list_windows() {
        tmux list-windows -a -F '#{session_name}:#{window_index}\tW\t#{window_name} (#{window_panes} panes)'
      }

      list_panes() {
        tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}\tP\t#{pane_current_command}  #{pane_current_path}'
      }

      pick_and_go() {
        local sel target type
        sel=$(cat | fzf --prompt="''${1}> " --height 40% --border --with-nth=1,3 --delimiter='\t' --ansi || true)
        [[ -z "$sel" ]] && exit 0
        target=$(printf '%s' "$sel" | awk -F '\t' '{print $1}')
        type=$(printf '%s' "$sel" | awk -F '\t' '{print $2}')
        case "$type" in
          S) tmux switch-client -t "$target" ;;
          W) tmux select-window -t "$target" ;;
          P) tmux select-pane -t "$target" ; tmux display-message "Switched to $target" ;;
        esac
      }

      case "$mode" in
        sessions)
          list_sessions | pick_and_go Sessions
          ;;
        windows)
          list_windows | pick_and_go Windows
          ;;
        panes)
          list_panes | pick_and_go Panes
          ;;
        all)
          {
            list_sessions
            list_windows
            list_panes
          } | pick_and_go Switch
          ;;
        *)
          tmux display-message "Unknown mode: $mode"
          ;;
      esac
    '';
  };

  # tmux-sessionizer: pick a directory and jump/create a session for it
  home.file.".local/bin/tmux-sessionizer" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      notify() {
        if [[ -n "''${TMUX:-}" ]]; then
          tmux display-message "$*"
        else
          printf '%s\n' "$*" >&2
        fi
      }

      if ! command -v tmux >/dev/null 2>&1; then
        notify "tmux not found"
        exit 1
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        notify "fzf not installed"
        exit 0
      fi

      pick_dir() {
        if command -v zoxide >/dev/null 2>&1; then
          zoxide query -l
          return 0
        fi

        # Fallback: a small set of common roots (cheap scan depth)
        roots=()
        for r in "$HOME/dev" "$HOME/code" "$HOME/projects" "$HOME/work" "$HOME"; do
          [[ -d "$r" ]] && roots+=("$r")
        done
        fd -t d -d 4 . "''${roots[@]}" 2>/dev/null | sort -u
      }

      dir="''${1:-}"
      if [[ -z "$dir" ]]; then
        dir="$(pick_dir | fzf --prompt='Session dir> ' --height 40% --border --cycle --exit-0)" || exit 0
      fi
      [[ -z "$dir" ]] && exit 0

      # Expand ~ and resolve to an existing directory
      dir="''${dir/#\\~/$HOME}"
      [[ -d "$dir" ]] || { notify "Not a directory: $dir"; exit 0; }

      # Prefer the repo root if inside a Git worktree
      if command -v git >/dev/null 2>&1; then
        if top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"; then
          dir="$top"
        fi
      fi

      base="$(basename "$dir")"
      base="''${base//./_}"
      base="$(printf '%s' "$base" | tr -cd '[:alnum:]_-')"
      hash="$(printf '%s' "$dir" | sha1sum | awk '{print substr($1,1,6)}')"
      session="''${base:-session}-''${hash}"

      if ! tmux has-session -t "$session" 2>/dev/null; then
        tmux new-session -d -s "$session" -c "$dir"
      fi

      if [[ -n "''${TMUX:-}" ]]; then
        tmux switch-client -t "$session"
      else
        tmux attach -t "$session"
      fi
    '';
  };

  # tmux-kube status snippet: show k8s context/namespace if available
  home.file.".local/bin/tmux-kube" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      if ! command -v kubectl >/dev/null 2>&1; then
        exit 0
      fi

      ctx=$(kubectl config current-context 2>/dev/null || true)
      [[ -z "$ctx" ]] && exit 0

      ns=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || true)
      [[ -z "$ns" ]] && ns=default

      # Minimal formatting with a kube symbol
      printf ' ⎈ %s/%s ' "$ctx" "$ns"
    '';
  };

  # tmux-git: show Git branch + short status for active pane path
  home.file.".local/bin/tmux-git" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Active pane path
      dir=$(tmux display -p -F '#{pane_current_path}')
      if ! top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
        exit 0
      fi

      branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo '?')

      dirty=""
      if [[ -n "$(git -C "$dir" status --porcelain=v1 2>/dev/null)" ]]; then
        dirty='*'
      fi

      ahead=""; behind=""
      if upstream=$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null); then
        read -r L R < <(git -C "$dir" rev-list --left-right --count "$upstream"...HEAD 2>/dev/null || echo "0 0")
        [[ ''${R:-0} -gt 0 ]] && ahead="⇡''${R}"
        [[ ''${L:-0} -gt 0 ]] && behind="⇣''${L}"
      fi

      bits=()
      bits+=(" ''${branch}''${dirty}")
      [[ -n "$ahead" ]] && bits+=("$ahead")
      [[ -n "$behind" ]] && bits+=("$behind")
      printf ' %s ' "''${bits[*]}"
    '';
  };

  # tmux-weather: pinned to Armenia, Quindío, Colombia in Celsius
  # home.file.".local/bin/tmux-weather" = {
  #   executable = true;
  #   text = ''
  #     #!/usr/bin/env bash
  #     set -euo pipefail
  #     LOC='Armenia, Quindío, Colombia'
  #     # Simple temperature output like '+24°C'; short timeout to avoid hangs
  #     if command -v curl >/dev/null 2>&1; then
  #       curl -m 2 -fsSL "https://wttr.in/''${LOC// /%20}?format=%t" 2>/dev/null || true
  #     fi
  #   '';
  # };

  home.sessionVariables =
    {
      YAZI_FILE_MANAGER = "yazi";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      FILE_MANAGER = "dolphin";
    };
}
