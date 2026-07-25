{
  config,
  pkgs,
  lib,
  ...
}: {
  programs = {
    zsh = {
      enable = true;
      dotDir = config.home.homeDirectory;
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

        # Make Ctrl-V paste the system clipboard at the shell prompt.
        # Ctrl-Shift-V is still handled by the terminal; Ctrl-Q keeps quoted-insert available.
        clipboard-paste-widget() {
          emulate -L zsh
          local pasted
          pasted="$("$HOME/.local/bin/tmux-paste" --print 2>/dev/null)" || return 0
          [[ -n "$pasted" ]] || return 0
          LBUFFER+="$pasted"
        }
        zle -N clipboard-paste-widget
        bindkey '^V' clipboard-paste-widget
        bindkey '^Q' quoted-insert

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

        # Notify when long commands finish (>10s) while pane is not active
        zmodload zsh/datetime 2>/dev/null || true
        _CMD_START=0
        _CMD_NAME=""
        _notify_preexec() { _CMD_START=$EPOCHSECONDS; _CMD_NAME="''${1%%$'\n'*}"; }
        _notify_precmd() {
          local elapsed=$(( EPOCHSECONDS - _CMD_START ))
          if (( _CMD_START > 0 && elapsed >= 10 )); then
            if [[ -n "''${TMUX:-}" ]]; then
              local active; active=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
              if [[ "$active" != "''${TMUX_PANE:-}" ]]; then
                local msg="Done (''${elapsed}s): ''${_CMD_NAME:0:60}"
                tmux display-message "$msg" 2>/dev/null || true
                command notify-send -t 4000 -a tmux "Command finished" "$msg" 2>/dev/null || true
              fi
            fi
          fi
          _CMD_START=0
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook preexec _notify_preexec
        add-zsh-hook precmd _notify_precmd

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
          gapa = "git add --patch";
          gc = "git commit -v";
          gcmsg = "git commit -m";
          "gc!" = "git commit -v --amend";
          gca = "git commit -v -a";
          "gca!" = "git commit -v -a --amend";
          gco = "git checkout";
          gcb = "git checkout -b";
          gcm = "git switch main";
          gcd = "git switch develop";
          gsw = "git switch";
          gswc = "git switch -c";
          gst = "git status";
          gss = "git status -s";
          gp = "git push";
          gpu = "git push -u origin HEAD";
          gpf = "git push --force-with-lease";
          gl = "git pull";
          gpr = "git pull --rebase";
          gf = "git fetch";
          gfa = "git fetch --all --prune";
          gd = "git diff";
          gds = "git diff --staged";
          gdc = "git diff --cached";
          gdt = "git difftool";
          gb = "git branch";
          gba = "git branch -a";
          gbd = "git branch -d";
          gbD = "git branch -D";
          gm = "git merge";
          gmt = "git mergetool";
          grb = "git rebase";
          grba = "git rebase --abort";
          grbc = "git rebase --continue";
          grbi = "git rebase -i";
          grh = "git reset HEAD";
          grhh = "git reset --hard HEAD";
          gcp = "git cherry-pick";
          gcpa = "git cherry-pick --abort";
          gcpc = "git cherry-pick --continue";
          grv = "git remote -v";
          gra = "git remote add";
          grrm = "git remote remove";
          gcl = "git clone";
          gsh = "git show";
          gstaa = "git stash apply";
          gstc = "git stash clear";
          gstd = "git stash drop";
          gstl = "git stash list";
          gstp = "git stash pop";
          gsts = "git stash show --patch";
          gclean = "git clean -fd";
          gcf = "git config --list";
          glog = "git log --oneline --graph";
          gloga = "git log --oneline --graph --decorate --all";
          lg = "lazygit";

          # Tmuxinator
          mux = "tmuxinator";
          muxp = "mux-session personal";
          muxd = "tmux-doctor";
          muxdoctor = "tmux-doctor";
          tsave = "tmux-save";
          tsavelight = "tmux-save --light";
          trestore = "tmux-restore";
          tresume = "tmux-resume";
          tlast = "tmux-last";

          # Security — install gitleaks pre-commit hook in existing repos
          git-secrets-install = ''[ -d .git ] && cp ~/.git-templates/hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit && echo "gitleaks pre-commit hook installed" || echo "not a git repo"'';

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

          # AI tools read credentials from each tool's normal environment/config.
          opencode = "opencode";
          aider = "aider";
          gemini = "gemini";
          qwen = "qwen";
          ccr-code = "npx -y @musistudio/claude-code-router start";
          ccr-ui = "npx -y @musistudio/claude-code-router ui";
          claude-code-temp = "npx -y claude-code-templates@latest";

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
          # Runs darwin-rebuild (macOS), nixos-rebuild (NixOS), or home-manager (else; DOTFILES_PROFILE default ubuntu-dev)
          rebuild = "bash $HOME/.dotfiles/system/scripts/rebuild";
          hm-switch = "bash $HOME/.dotfiles/system/scripts/rebuild";
          rebuild-home = "bash $HOME/.dotfiles/system/scripts/rebuild";
          rebuild-proxmox = "bash $HOME/.dotfiles/system/scripts/rebuild nixos-proxmox";
          rebuild-test = "sudo nixos-rebuild test --flake '/home/felipe/.dotfiles#default'";
          rebuild-boot = "sudo nixos-rebuild boot --flake '/home/felipe/.dotfiles#default'";
          update-flake = "nix flake update --flake /home/felipe/.dotfiles/";
          update-claude-desktop = "cd /home/felipe/.local/share/claude-desktop && git pull && bash install.sh";
          # Network (Linux)
          ip = "ip -color=auto";

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

    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = config.programs.zsh.shellAliases;
      initExtra = ''
        if [[ $- != *i* ]]; then
          return
        fi

        # Keep readline responsive and match the interactive shell defaults.
        stty -ixon -ixoff 2>/dev/null || true
        export DISABLE_AUTO_TITLE="true"

        eval "$(${pkgs.starship}/bin/starship init bash)"
        eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
        eval "$(${pkgs.atuin}/bin/atuin init bash --disable-up-arrow)"
      '';
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
        tmux-sessionx
        tmux-thumbs
        tmux-floax
        tmux-fzf
      ];
      extraConfig = ''
        # Prefix: Ctrl+Space locally; Ctrl+b passes through naturally to nested remote tmux
        set -g prefix C-Space
        bind C-Space send-prefix

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
         # Integrate copy with system clipboard and tmux buffer.
         set -s set-clipboard on
         bind-key -T copy-mode-vi 'v' send -X begin-selection
         bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel '~/.local/bin/tmux-copy'
         bind-key -T copy-mode-vi 'r' send -X rectangle-toggle
         # Copy on mouse selection (drag release) for both key tables
         bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel '~/.local/bin/tmux-copy'
         bind-key -T copy-mode MouseDragEnd1Pane send -X copy-pipe-and-cancel '~/.local/bin/tmux-copy'
         # Prefix+] / Prefix+P paste from system clipboard, falling back to tmux buffer.
         bind ] run-shell -b "~/.local/bin/tmux-paste --tmux-send"
         bind P run-shell -b "~/.local/bin/tmux-paste --tmux-send"

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
         set -g pane-border-format " #{pane_index} #{?#{!=:#{pane_title},},#{=-15:pane_title} · ,}#{pane_current_command} #{=-30:pane_current_path}"

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
        bind -n M-0 select-window -t 10
        bind -n M-w choose-tree -Zw

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
         set -g status-interval 10
         set -g status-justify centre

         # Status bar base - transparent feel with margins
         set -g status-style "bg=#1e1e2e"
         set -g status-left-length 100
         set -g status-right-length 100

         # Left: Session color changes per session (personal=mauve, work=green, default=blue)
         set -g status-left "#{?#{==:#S,personal},#[fg=#1e1e2e,bg=#cba6f7,bold]  #S #[fg=#cba6f7,bg=#1e1e2e],#{?#{==:#S,work},#[fg=#1e1e2e,bg=#a6e3a1,bold]  #S #[fg=#a6e3a1,bg=#1e1e2e],#[fg=#1e1e2e,bg=#89b4fa,bold]  #S #[fg=#89b4fa,bg=#1e1e2e]}}   "

         # Right: Prefix / Copy indicators + Directory + Time + Date
         set -g status-right "#{?client_prefix,#[fg=#1e1e2e,bg=#fab387,bold]  PREFIX  #[fg=#fab387,bg=#1e1e2e],}#{?#{==:#{pane_mode},copy-mode},#[fg=#1e1e2e,bg=#f5c2e7,bold]  COPY  #[fg=#f5c2e7,bg=#1e1e2e],}#[fg=#313244,bg=#1e1e2e]#[fg=#cdd6f4,bg=#313244]  #{b:pane_current_path} #[fg=#1e1e2e,bg=#313244]#[fg=#313244,bg=#1e1e2e] #[fg=#45475a,bg=#1e1e2e]#[fg=#a6adc8,bg=#45475a]  %H:%M #[fg=#89b4fa,bg=#45475a]#[fg=#1e1e2e,bg=#89b4fa]  %d %b #[fg=#89b4fa,bg=#1e1e2e]"

         # Window status - clean pills with spacing
         set -g window-status-separator "  "
         set -g window-status-format "#[fg=#313244,bg=#1e1e2e]#[fg=#6c7086,bg=#313244] #I  #W #{?window_zoomed_flag,#[fg=#f9e2af]Z ,}#[fg=#313244,bg=#1e1e2e]"
         set -g window-status-current-format "#[fg=#a6e3a1,bg=#1e1e2e]#[fg=#1e1e2e,bg=#a6e3a1,bold] #I  #W #{?window_zoomed_flag,#[fg=#1e1e2e]🔍 ,}#[fg=#a6e3a1,bg=#1e1e2e]"
         set -g window-status-activity-style "fg=#fab387,bg=#1e1e2e"
         set -g window-status-bell-style "fg=#f38ba8,bg=#1e1e2e,bold"

         # Pane borders - unmistakable separation from content
         set -g pane-border-lines double
         set -g pane-border-style "fg=#a6adc8"
         set -g pane-active-border-style "fg=#89b4fa,bold"
         # Colored pane headers that match the border palette
         set -g pane-border-format "#[fg=#6c7086] #{pane_index} #[fg=#a6adc8]#{pane_current_command}#[fg=#6c7086] · #{=-20:pane_current_path} "

         # Message and mode styling
         set -g message-style "fg=#cdd6f4,bg=#313244"
         set -g message-command-style "fg=#cdd6f4,bg=#45475a,bold"
         set -g mode-style "fg=#1e1e2e,bg=#f5c2e7"
         set -g menu-style "fg=#cdd6f4,bg=#313244"
         set -g menu-selected-style "fg=#1e1e2e,bg=#89b4fa,bold"
         set -g menu-border-style "fg=#45475a"
         set -g menu-border-lines double

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

        # Broadcast: toggle sync to all panes in current window
        bind * setw synchronize-panes \; display-message "Sync panes: #{?pane_synchronized,ON,OFF}"

        # Broadcast: send command to all SSH panes in session via popup
        bind M run-shell -b "~/.local/bin/tmux-broadcast"

        # Sidebar toggle (yazi/ranger) - alternative: prefix+F for floax
        bind b run-shell -b "~/.local/bin/tmux-sidebar toggle"
        bind B run-shell -b "~/.local/bin/tmux-sidebar open 40"

        # Extract items (URLs, emails, SHAs, paths) from scrollback (alternative: prefix+Space for thumbs)
        bind e run-shell -b "~/.local/bin/tmux-extracto"

        # Session restore
        set -g @resurrect-capture-pane-contents 'on'
        set -g @resurrect-pane-contents-area 'full'
        set -g @resurrect-processes 'ssh mosh-client psql mysql sqlite3 k9s lazygit btop htop yazi ranger lf "~kubectl" "~journalctl" "~nix develop" "~claude" "~gemini" "~qwen" "~opencode" "~hermes" "~nvim" "~vim" "~npm" "~yarn" "~pnpm" "~bun" "~node" "~python"'
        set -g @continuum-restore 'off'
        set -g @continuum-save-interval '0'

        # Plugin configurations (plugins are installed by Home Manager/Nix)

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
        set -g @thumbs-command 'echo -n {} | ~/.local/bin/tmux-copy'
        set -g @thumbs-upcase-command 'echo -n {} | xdg-open'

        # tmux-fzf: FZF integration for tmux
        TMUX_FZF_LAUNCH_KEY="C-f"
        TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"

        # Show neofetch on session creation
        set-hook -ga session-created 'run-shell "${pkgs.neofetch}/bin/neofetch"'
      '';
    };
  };

  # Tmux session persistence across reboots
  # systemd (Linux): light periodic save + full save on shutdown
  systemd.user.services.tmux-resurrect-save = {
    Unit = {
      Description = "Save tmux sessions for resurrect";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -lc '${config.home.homeDirectory}/.local/bin/tmux-save --light >/dev/null 2>&1 || true'";
      Nice = 10;
      IOSchedulingClass = "idle";
      CPUQuota = "25%";
      CPUWeight = 20;
    };
  };

  systemd.user.timers.tmux-resurrect-save = {
    Unit = {
      Description = "Periodic tmux session save";
    };
    Timer = {
      OnActiveSec = "15m";
      OnBootSec = "10m";
      OnUnitInactiveSec = "15m";
      Persistent = true;
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };

  systemd.user.services.tmux-resurrect-shutdown = {
    Unit = {
      Description = "Save tmux sessions before shutdown";
      Before = ["shutdown.target"];
      DefaultDependencies = false;
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -lc '${config.home.homeDirectory}/.local/bin/tmux-save >/dev/null 2>&1 || true'";
    };
    Install = {
      WantedBy = ["shutdown.target"];
    };
  };

  # launchd (macOS): save every 5 minutes
  launchd.agents.tmux-resurrect-save = {
    enable = pkgs.stdenv.isDarwin;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "$HOME/.local/bin/tmux-save --light >/dev/null 2>&1 || true"
      ];
      StartInterval = 900;
      RunAtLoad = true;
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
          else printf '%s' "$val" | "$HOME/.local/bin/tmux-copy"; fi
          ;;
        EMAIL|SHA|PATH)
          printf '%s' "$val" | "$HOME/.local/bin/tmux-copy"
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

  # mux-session: declarative tmuxinator sessions by default; resurrect is explicit.
  home.file.".local/bin/mux-session" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      usage() {
        printf '%s\n' \
          "Usage: mux-session personal [--restart|--restore|--doctor]" \
          "" \
          "Default:" \
          "  Attach/switch to the existing session, or start the tmuxinator layout cleanly." \
          "" \
          "Modes:" \
          "  --restart  Save a resurrect snapshot, kill only this session, then start tmuxinator cleanly." \
          "  --restore  Run tmux resurrect, then attach/switch to the requested session if present." \
          "  --doctor   Run tmux-doctor."
      }

      if [[ "''${1:-}" == "--help" || "''${1:-}" == "-h" ]]; then
        usage
        exit 0
      fi

      session="''${1:-}"
      mode="start"
      [[ -n "$session" ]] || { usage >&2; exit 2; }
      [[ "$session" == "personal" ]] || { usage >&2; exit 2; }
      shift || true

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --restart|-r) mode="restart" ;;
          --restart-detached) mode="restart-detached" ;;
          --restore) mode="restore" ;;
          --doctor) mode="doctor" ;;
          --help|-h) usage; exit 0 ;;
          *) echo "mux-session: unknown option: $1" >&2; usage >&2; exit 2 ;;
        esac
        shift
      done

      notify() {
        if [[ -n "''${TMUX:-}" ]]; then
          tmux display-message "$*"
        else
          printf '%s\n' "$*" >&2
        fi
      }

      attach_or_switch() {
        local target="$1"
        if [[ -n "''${TMUX:-}" ]]; then
          exec tmux switch-client -t "$target"
        fi
        exec tmux attach-session -t "$target"
      }

      start_tmuxinator() {
        local project="$1"
        if ! command -v tmuxinator >/dev/null 2>&1; then
          echo "tmuxinator not found" >&2
          exit 127
        fi
        exec tmuxinator start "$project"
      }

      start_tmuxinator_detached() {
        local project="$1"
        if ! command -v tmuxinator >/dev/null 2>&1; then
          echo "tmuxinator not found" >&2
          exit 127
        fi
        tmuxinator start "$project" --no-attach
      }

      case "$mode" in
        doctor)
          exec "$HOME/.local/bin/tmux-doctor"
          ;;
        restore)
          "$HOME/.local/bin/tmux-restore"
          if tmux has-session -t "$session" 2>/dev/null; then
            attach_or_switch "$session"
          fi
          first="$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -v '^restore-bootstrap$' | head -n1 || true)"
          [[ -n "''${first:-}" ]] && attach_or_switch "$first"
          exit 0
          ;;
        restart)
          current_session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
          if [[ -n "''${TMUX:-}" && "$current_session" == "$session" ]]; then
            tmux run-shell -b "$HOME/.local/bin/mux-session $session --restart-detached"
            exit 0
          fi
          if tmux has-session -t "$session" 2>/dev/null; then
            "$HOME/.local/bin/tmux-save" >/dev/null 2>&1 || true
            tmux kill-session -t "$session"
            notify "Restarting tmux session: $session"
          fi
          start_tmuxinator "$session"
          ;;
        restart-detached)
          if tmux has-session -t "$session" 2>/dev/null; then
            "$HOME/.local/bin/tmux-save" >/dev/null 2>&1 || true
            tmux kill-session -t "$session"
          fi
          start_tmuxinator_detached "$session"
          if tmux has-session -t "$session" 2>/dev/null; then
            tmux switch-client -t "$session" 2>/dev/null || true
          fi
          ;;
        start)
          if tmux has-session -t "$session" 2>/dev/null; then
            attach_or_switch "$session"
          fi
          start_tmuxinator "$session"
          ;;
      esac
    '';
  };

  # tmux-doctor: quick health checks for tmux, tmuxinator, resurrect, clipboard, and k8s.
  home.file.".local/bin/tmux-doctor" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      ok=0
      warn=0
      fail=0

      pass() { printf 'OK    %s\n' "$*"; ok=$((ok + 1)); }
      note() { printf 'WARN  %s\n' "$*"; warn=$((warn + 1)); }
      bad() { printf 'FAIL  %s\n' "$*"; fail=$((fail + 1)); }

      have() { command -v "$1" >/dev/null 2>&1; }

      check_cmd() {
        local cmd="$1"
        if have "$cmd"; then pass "command: $cmd ($(command -v "$cmd"))"; else bad "missing command: $cmd"; fi
      }

      check_optional_cmd() {
        local cmd="$1"
        if have "$cmd"; then pass "optional command: $cmd"; else note "optional command missing: $cmd"; fi
      }

      check_file() {
        local path="$1"
        if [[ -e "$path" ]]; then pass "file exists: $path"; else bad "missing file: $path"; fi
      }

      check_executable() {
        local path="$1"
        if [[ -x "$path" ]]; then pass "executable: $path"; else bad "not executable/missing: $path"; fi
      }

      echo "tmux doctor"
      echo "==========="

      check_cmd tmux
      check_cmd tmuxinator
      check_optional_cmd fzf
      check_optional_cmd yazi
      check_optional_cmd btop
      check_optional_cmd k9s

      for helper in mux-session tmux-copy tmux-paste tmux-save tmux-restore tmux-git tmux-kube tmux-fzf-switch; do
        check_executable "$HOME/.local/bin/$helper"
      done

      for project in personal; do
        config="$HOME/.config/tmuxinator/$project.yml"
        repo_config="$HOME/.dotfiles/export/tmuxinator/$project.yml"
        if [[ -L "$config" ]]; then
          target="$(readlink "$config" 2>/dev/null || true)"
          pass "tmuxinator symlink: $project -> $target"
        elif [[ -e "$config" ]]; then
          note "tmuxinator config is not a symlink: $config"
        else
          bad "missing tmuxinator config: $config"
        fi

        check_file "$repo_config"
        if tmuxinator debug "$project" -n "$project-doctor" --no-attach >/tmp/tmuxinator-"$project".doctor 2>&1; then
          pass "tmuxinator debug: $project"
        else
          bad "tmuxinator debug failed: $project (see /tmp/tmuxinator-$project.doctor)"
        fi
      done

      if tmux has-session 2>/dev/null; then
        pass "tmux server has sessions: $(tmux list-sessions -F '#{session_name}' 2>/dev/null | tr '\n' ' ')"
        continuum_restore="$(tmux show-option -gqv @continuum-restore 2>/dev/null || true)"
        if [[ "$continuum_restore" == "off" ]]; then
          pass "continuum restore is explicit/manual"
        else
          note "continuum restore is '$continuum_restore' in the running server; reload tmux config if this should be off"
        fi
      else
        note "no tmux server running"
      fi

      if [[ -e "$HOME/.tmux/resurrect/last" ]]; then
        pass "resurrect snapshot: $(readlink -f "$HOME/.tmux/resurrect/last" 2>/dev/null || printf '%s' "$HOME/.tmux/resurrect/last")"
      else
        note "no resurrect snapshot at ~/.tmux/resurrect/last"
      fi

      if have wl-copy || have xclip || have xsel || have pbcopy; then
        pass "clipboard copy backend available"
      else
        note "no system clipboard copy backend; tmux buffer fallback will still work"
      fi

      if have wl-paste || have xclip || have xsel || have pbpaste; then
        pass "clipboard paste backend available"
      else
        note "no system clipboard paste backend; tmux buffer fallback will still work"
      fi

      tmux_conf="''${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
      for plugin in sessionx tmux-thumbs tmux-floax tmux-fzf; do
        if [[ -r "$tmux_conf" ]] && grep -q "$plugin" "$tmux_conf"; then
          pass "Home Manager tmux plugin configured: $plugin"
        elif [[ -d "$HOME/.tmux/plugins/$plugin" ]]; then
          pass "TPM plugin installed: $plugin"
        else
          note "tmux plugin not found in Home Manager config or TPM dir: $plugin"
        fi
      done

      echo
      printf 'Summary: %d OK, %d WARN, %d FAIL\n' "$ok" "$warn" "$fail"
      [[ "$fail" -eq 0 ]]
    '';
  };

  # tmux-copy: copy stdin to system clipboard and tmux buffer.
  home.file.".local/bin/tmux-copy" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      tmp="$(mktemp)"
      trap 'rm -f "$tmp"' EXIT
      cat > "$tmp"

      if [[ -n "''${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
        tmux load-buffer "$tmp" 2>/dev/null || true
      fi

      copied=0
      if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$tmp" && copied=1
      elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -in < "$tmp" && copied=1
      elif command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --input < "$tmp" && copied=1
      elif command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "$tmp" && copied=1
      fi

      if [[ -n "''${TMUX:-}" ]]; then
        if [[ "$copied" -eq 1 ]]; then
          tmux display-message "Copied to clipboard and tmux buffer" 2>/dev/null || true
        else
          tmux display-message "Copied to tmux buffer; no system clipboard backend" 2>/dev/null || true
        fi
      fi

      exit 0
    '';
  };

  # tmux-paste: read system clipboard with tmux buffer fallback.
  home.file.".local/bin/tmux-paste" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      mode="''${1:---print}"

      read_clipboard() {
        if command -v wl-paste >/dev/null 2>&1; then
          wl-paste --no-newline 2>/dev/null || wl-paste 2>/dev/null
        elif command -v xclip >/dev/null 2>&1; then
          xclip -selection clipboard -out 2>/dev/null
        elif command -v xsel >/dev/null 2>&1; then
          xsel --clipboard --output 2>/dev/null
        elif command -v pbpaste >/dev/null 2>&1; then
          pbpaste 2>/dev/null
        else
          return 1
        fi
      }

      text="$(read_clipboard || true)"
      if [[ -z "$text" && -n "''${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
        text="$(tmux save-buffer - 2>/dev/null || true)"
      fi

      case "$mode" in
        --print)
          printf '%s' "$text"
          ;;
        --tmux-send)
          if [[ -z "$text" ]]; then
            tmux display-message "Clipboard and tmux buffer are empty" 2>/dev/null || true
            exit 0
          fi
          tmp="$(mktemp)"
          trap 'rm -f "$tmp"' EXIT
          printf '%s' "$text" > "$tmp"
          tmux load-buffer "$tmp"
          tmux paste-buffer
          ;;
        *)
          echo "Usage: tmux-paste [--print|--tmux-send]" >&2
          exit 2
          ;;
      esac
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

      cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/tmux-status"
      mkdir -p "$cache_dir"
      kubeconfig_key="$(printf '%s' "''${KUBECONFIG:-$HOME/.kube/config}" | sha1sum | awk '{print $1}')"
      cache="$cache_dir/kube-$kubeconfig_key.txt"
      interval="''${TMUX_KUBE_STATUS_INTERVAL:-30}"
      now="$(date +%s)"
      mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }

      if [[ -s "$cache" ]]; then
        last="$(mtime "$cache")"
        if [[ $((now - last)) -lt "$interval" ]]; then
          cat "$cache"
          exit 0
        fi
      fi

      if command -v timeout >/dev/null 2>&1; then
        ctx=$(timeout 1s kubectl config current-context 2>/dev/null || true)
      else
        ctx=$(kubectl config current-context 2>/dev/null || true)
      fi
      [[ -z "$ctx" ]] && { : > "$cache"; exit 0; }

      if command -v timeout >/dev/null 2>&1; then
        ns=$(timeout 1s kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || true)
      else
        ns=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || true)
      fi
      [[ -z "$ns" ]] && ns=default

      out="$(printf ' ⎈ %s/%s ' "$ctx" "$ns")"
      printf '%s' "$out" > "$cache"
      printf '%s' "$out"
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

      cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/tmux-status"
      mkdir -p "$cache_dir"
      key="$(printf '%s' "$top" | sha1sum | awk '{print $1}')"
      cache="$cache_dir/git-$key.txt"
      interval="''${TMUX_GIT_STATUS_INTERVAL:-20}"
      now="$(date +%s)"
      mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }

      if [[ -s "$cache" ]]; then
        last="$(mtime "$cache")"
        if [[ $((now - last)) -lt "$interval" ]]; then
          cat "$cache"
          exit 0
        fi
      fi

      branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo '?')

      dirty=""
      if command -v timeout >/dev/null 2>&1; then
        status="$(timeout 1s git -C "$dir" status --porcelain=v1 2>/dev/null || true)"
      else
        status="$(git -C "$dir" status --porcelain=v1 2>/dev/null || true)"
      fi
      if [[ -n "$status" ]]; then
        dirty='*'
      fi

      ahead=""; behind=""
      if upstream=$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null); then
        if command -v timeout >/dev/null 2>&1; then
          read -r L R < <(timeout 1s git -C "$dir" rev-list --left-right --count "$upstream"...HEAD 2>/dev/null || echo "0 0")
        else
          read -r L R < <(git -C "$dir" rev-list --left-right --count "$upstream"...HEAD 2>/dev/null || echo "0 0")
        fi
        [[ ''${R:-0} -gt 0 ]] && ahead="⇡''${R}"
        [[ ''${L:-0} -gt 0 ]] && behind="⇣''${L}"
      fi

      bits=()
      bits+=(" ''${branch}''${dirty}")
      [[ -n "$ahead" ]] && bits+=("$ahead")
      [[ -n "$behind" ]] && bits+=("$behind")
      out="$(printf ' %s ' "''${bits[*]}")"
      printf '%s' "$out" > "$cache"
      printf '%s' "$out"
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

  # tmux-resurrect-save: save session state before muxp/muxw kill+recreate
  home.file.".local/bin/tmux-resurrect-save" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec "$HOME/.local/bin/tmux-save" "$@"
    '';
  };

  home.file.".local/bin/tmux-save" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      mode="full"
      case "''${1:-}" in
        --light|--timer) mode="light" ;;
        --full|"") mode="full" ;;
        --help|-h)
          printf '%s\n' \
            "Usage: tmux-save [--full|--light]" \
            "" \
            "--full   Capture layout, processes, and full pane contents. Default for manual saves." \
            "--light  Capture layout/processes only. Intended for periodic timers."
          exit 0
          ;;
        *) echo "tmux-save: unknown option: $1" >&2; exit 2 ;;
      esac

      if ! tmux has-session 2>/dev/null; then
        echo "No hay sesiones de tmux abiertas para guardar." >&2
        exit 1
      fi

      if [[ "$mode" == "light" ]]; then
        tmux set-option -gq @resurrect-capture-pane-contents 'off'
      else
        tmux set-option -gq @resurrect-capture-pane-contents 'on'
        tmux set-option -gq @resurrect-pane-contents-area 'full'
      fi
      tmux set-option -gq @resurrect-processes 'ssh mosh-client psql mysql sqlite3 k9s lazygit btop htop yazi ranger lf "~kubectl" "~journalctl" "~nix develop" "~claude" "~codex" "~gemini" "~qwen" "~npm" "~yarn" "~pnpm" "~bun" "~node" "~python"'

      tmux run-shell "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh"
      sleep 1

      # captura session-ids de agentes (codex) por pane para poder resumirlos
      "$HOME/.local/bin/tmux-capture-agents" 2>/dev/null || true

      last="$HOME/.tmux/resurrect/last"
      if [[ -e "$last" ]]; then
        target=$(readlink -f "$last" 2>/dev/null || printf '%s' "$last")
        panes=$(grep -c $'^pane\t' "$target" 2>/dev/null || true)
        windows=$(grep -c $'^window\t' "$target" 2>/dev/null || true)
        commands=$(awk -F '\t' '$1=="pane" && $11 != ":" && $11 != "" { count++ } END { print count + 0 }' "$target" 2>/dev/null || true)
        contents="no"
        if [[ "$mode" == "light" ]]; then
          contents="skipped"
        elif [[ -s "$HOME/.tmux/resurrect/pane_contents.tar.gz" ]]; then
          contents="yes"
        fi
        echo "tmux guardado ($mode): $target"
        echo "capturado: ''${windows:-0} ventanas, ''${panes:-0} panes"
        echo "procesos activos capturados: ''${commands:-0}"
        echo "contenido de panes capturado: $contents"
      fi
    '';
  };

  home.file.".local/bin/tmux-restore" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      last="$HOME/.tmux/resurrect/last"
      if [[ ! -e "$last" ]]; then
        echo "No hay snapshot de tmux para restaurar en ~/.tmux/resurrect/last." >&2
        exit 1
      fi

      if ! tmux has-session 2>/dev/null; then
        tmux new-session -d -s restore-bootstrap
      fi

      tmux set-option -gq @resurrect-capture-pane-contents 'on'
      tmux set-option -gq @resurrect-pane-contents-area 'full'
      tmux set-option -gq @resurrect-processes 'ssh mosh-client psql mysql sqlite3 k9s lazygit btop htop yazi ranger lf "~kubectl" "~journalctl" "~nix develop" "~claude" "~codex" "~gemini" "~qwen" "~npm" "~yarn" "~pnpm" "~bun" "~node" "~python"'

      tmux run-shell "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh"
      sleep 2

      # resurrect es async para sesiones grandes; los agentes se inyectan con poll
      "$HOME/.local/bin/tmux-restore-agents" 2>/dev/null || true
      echo "tmux restaurado desde: $(readlink -f "$last" 2>/dev/null || printf '%s' "$last")"
      tmux list-sessions
    '';
  };

  home.file.".local/bin/tmux-resume" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      "$HOME/.local/bin/tmux-restore"
      session=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -v '^restore-bootstrap$' | head -n1 || true)
      if [[ -z "''${session:-}" ]]; then
        session=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | head -n1 || true)
      fi
      [[ -n "''${session:-}" ]] || exit 0
      exec tmux attach-session -t "$session"
    '';
  };

  # tmux-capture-agents: captura session-ids de agentes por pane (antes de apagar).
  # codex mantiene su rollout-*.jsonl abierto en un fd -> se lee via /proc y se
  # extrae el UUID. Asi podemos hacer "codex resume <uuid>" al restaurar.
  home.file.".local/bin/tmux-capture-agents" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      OUT="$HOME/.tmux/resurrect/agent_sessions.tsv"
      tmp="$(mktemp)"
      : > "$tmp"

      sep="$(printf '\t')"
      fmt="#{session_name}:#{window_index}.#{pane_index}''${sep}#{pane_tty}''${sep}#{pane_current_path}''${sep}#{pane_current_command}''${sep}#{pane_pid}"

      while IFS="$sep" read -r target tty path cmd pid; do
        [[ -n "''${tty:-}" && "''${tty:-}" != "/dev/null" ]] || continue
        agent=""
        sid=""
        case "$cmd" in
          codex)
            for cpid in $(pgrep -x codex 2>/dev/null || true); do
              fd0="$(readlink "/proc/$cpid/fd/0" 2>/dev/null || true)"
              [[ "$fd0" == "$tty" ]] || continue
              for fdl in /proc/$cpid/fd/*; do
                tgt="$(readlink "$fdl" 2>/dev/null || true)"
                case "$tgt" in
                  *rollout-*.jsonl)
                    agent="codex"
                    sid="$(basename "$tgt" | sed -E 's/^rollout-[0-9T:+-]*-([0-9a-f-]+)\.jsonl$/\1/')"
                    break
                    ;;
                esac
              done
              [[ -n "$sid" ]] && break
            done
            ;;
        esac
        if [[ -n "$agent" && -n "$sid" ]]; then
          printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$target" "$cmd" "$path" "$agent" "$sid" "$(date -Iseconds 2>/dev/null || echo unknown)" >> "$tmp"
        fi
      done < <(tmux list-panes -as -F "$fmt" 2>/dev/null || true)

      mv "$tmp" "$OUT"
      count="$(grep -c . "$OUT" 2>/dev/null || echo 0)"
      echo "agentes capturados: $count"
    '';
  };

  # tmux-restore-agents: corre despues de resurrect. Inyecta "codex resume <uuid>"
  # en cada pane que tenia un codex corriendo. Poll por pane (resurrect es async).
  home.file.".local/bin/tmux-restore-agents" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      MAP="$HOME/.tmux/resurrect/agent_sessions.tsv"
      if [[ ! -r "$MAP" ]]; then
        echo "no hay agent_sessions.tsv; nada que restaurar" >&2
        exit 0
      fi

      restored=0
      skipped=0
      while IFS=$'\t' read -r target cmd path agent sid ts; do
        [[ -n "''${agent:-}" && -n "''${sid:-}" ]] || continue
        [[ "$agent" == "codex" ]] || continue

        ready=0
        for _ in $(seq 1 40); do
          if tmux list-panes -t "$target" >/dev/null 2>&1; then ready=1; break; fi
          sleep 0.5
        done
        if [[ "$ready" -ne 1 ]]; then
          echo "skip (pane no creado por resurrect): $target" >&2
          skipped=$((skipped + 1))
          continue
        fi

        tmux send-keys -t "$target" "codex resume $sid" C-m
        restored=$((restored + 1))
        sleep 0.4
      done < "$MAP"

      echo "agentes codex restaurados: $restored (skipped: $skipped)"
    '';
  };

  home.file.".local/bin/tmux-last" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      last="$HOME/.tmux/resurrect/last"
      if [[ ! -e "$last" ]]; then
        echo "No hay snapshot en ~/.tmux/resurrect/last." >&2
        exit 1
      fi

      target=$(readlink -f "$last" 2>/dev/null || printf '%s' "$last")
      echo "$target"
      stat -c 'modificado: %y' "$target" 2>/dev/null || true
      printf 'sesiones: '; awk -F '\t' '$1=="window"{print $2}' "$target" | sort -u | tr '\n' ' '; echo
      echo "ventanas: $(grep -c $'^window\t' "$target" 2>/dev/null || true)"
      echo "panes: $(grep -c $'^pane\t' "$target" 2>/dev/null || true)"
      echo "procesos activos: $(awk -F '\t' '$1=="pane" && $11 != ":" && $11 != "" { count++ } END { print count + 0 }' "$target" 2>/dev/null || true)"
      [[ -s "$HOME/.tmux/resurrect/pane_contents.tar.gz" ]] && echo "contenido de panes: $HOME/.tmux/resurrect/pane_contents.tar.gz"
      agents="$HOME/.tmux/resurrect/agent_sessions.tsv"
      if [[ -s "$agents" ]]; then
        echo "agentes con resume (codex): $(grep -c . "$agents" 2>/dev/null || echo 0)"
        awk -F '\t' '{printf "  %s  %s  %s\n", $1, $4, $5}' "$agents"
      else
        echo "agentes con resume: 0"
      fi
    '';
  };

  # tmux-broadcast: send a command to all SSH panes in current session via popup
  home.file.".local/bin/tmux-broadcast" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      SESSION=$(tmux display-message -p '#{session_name}')

      mapfile -t SSH_PANES < <(
        tmux list-panes -a -s -t "$SESSION" \
          -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' \
          2>/dev/null | awk '$2=="ssh"{print $1}'
      )

      if [[ ''${#SSH_PANES[@]} -eq 0 ]]; then
        tmux display-message "No SSH panes in session '$SESSION'"
        exit 0
      fi

      cmd=$(tmux display-popup -E \
        -T " Broadcast → ''${#SSH_PANES[@]} SSH panes " \
        -w 70% -h 8 \
        "printf 'Command: '; read -r c; printf '%s' \"\$c\"" 2>/dev/null || true)

      [[ -z "''${cmd:-}" ]] && exit 0

      for pane in "''${SSH_PANES[@]}"; do
        tmux send-keys -t "$pane" "$cmd" Enter
      done

      tmux display-message "Broadcast to ''${#SSH_PANES[@]} panes: $cmd"
    '';
  };

  home.sessionVariables =
    {
      YAZI_FILE_MANAGER = "yazi";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      FILE_MANAGER = "dolphin";
    };
}
