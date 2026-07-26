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

        # ── ai-env: load local AI keys fallback for interactive shells ──────
        # The canonical source is Infisical; ~/.config/ai-keys.env is the
        # local fallback so tools launched directly (not via `ai-env`) still
        # resolve. Migrate to `ai-env <profile>` invocations over time and
        # this source can be removed for a keyless shell env.
        [ -r "$HOME/.dotfiles/system/scripts/ai-env-source.sh" ] && \
          source "$HOME/.dotfiles/system/scripts/ai-env-source.sh"

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
          muxw = "mux-session work";
          muxk = "mux-session komp";
          muxb = "mux-session blackrack";
          muxd = "tmux-doctor";
          muxdoctor = "tmux-doctor";
          tsave = "tmux-save";
          tsavelight = "tmux-save --light";
          trestore = "tmux-restore";
          tresume = "tmux-resume";
          tlast = "tmux-last";

          # Remote tmux — attach with synced config
          ssht = "bash $HOME/.dotfiles/system/scripts/tmux-auto-ssh.sh";
          tmux-sync = "bash $HOME/.dotfiles/system/scripts/tmux-sync-hosts.sh";

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

          # AI Tools — routed through ai-env (central secret router).
          # Each profile loads its keys from Infisical or ~/.config/ai-keys.env.
          opencode = "ai-env opencode";
          aider = "ai-env aider";
          gemini = "ai-env gemini";
          qwen = "ai-env qwen";
          claudia = "ai-env claudia";
          ccr-code = "ai-env ccr";
          # ccr-ui / claude-code-temp don't need model keys directly
          ccr-ui = "npx -y @musistudio/claude-code-router ui";
          claude-code-temp = "npx -y claude-code-templates@latest";
          ai-audit = "ai-secrets-audit";

          # Claude Code with separate config directories (all via ai-env for keys)
          claude-work = "CLAUDE_CONFIG_DIR=~/.claude-work ai-env claude";
          claude-very = "CLAUDE_CONFIG_DIR=~/.claude-very ai-env claude";
          claude-personal = "CLAUDE_CONFIG_DIR=~/.claude-personal ai-env claude";
          claude-overflow = "CLAUDE_CONFIG_DIR=~/.claude-overflow claude";

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
          vault-skills-sync = "bash $HOME/.dotfiles/system/scripts/vault-skills-sync";
          vault-skills-pull = "bash $HOME/.dotfiles/system/scripts/vault-skills-sync --pull";
          mcp-sync = "bash $HOME/.dotfiles/system/scripts/mcp-sync";
          mcp-sync-all = "bash $HOME/.dotfiles/system/scripts/mcp-sync --all";
          rebuild-home = "bash $HOME/.dotfiles/system/scripts/rebuild";
          rebuild-proxmox = "bash $HOME/.dotfiles/system/scripts/rebuild nixos-proxmox";
          rebuild-test = "sudo nixos-rebuild test --flake '/home/felipe/.dotfiles#default'";
          rebuild-boot = "sudo nixos-rebuild boot --flake '/home/felipe/.dotfiles#default'";
          update-flake = "nix flake update --flake /home/felipe/.dotfiles/";
          update-claude-desktop = "cd /home/felipe/.local/share/claude-desktop && git pull && bash install.sh";
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
          sysinfo = "fastfetch";
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
        # Keep the conventional previous-window action on Prefix+p. tmux-floax
        # claimed this key for a floating shell, so it is intentionally absent
        # from the plugin list above.
        unbind p
        bind p previous-window
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
         # A shared tmux bar does not need sub-minute polling. This keeps the
         # CPU widget cheap even when many Claude/Codex panes are open.
         set -g status-interval 60
         set -g status-justify centre

         # Status bar base - transparent feel with margins
         set -g status-style "bg=#1e1e2e"
         set -g status-left-length 100
         set -g status-right-length 100

         # Left: Session color changes per session (personal=mauve, work=green, default=blue)
         set -g status-left "#{?#{==:#S,personal},#[fg=#1e1e2e,bg=#cba6f7,bold]  #S #[fg=#cba6f7,bg=#1e1e2e],#{?#{==:#S,work},#[fg=#1e1e2e,bg=#a6e3a1,bold]  #S #[fg=#a6e3a1,bg=#1e1e2e],#[fg=#1e1e2e,bg=#89b4fa,bold]  #S #[fg=#89b4fa,bg=#1e1e2e]}}   "

         # Right: Prefix / Copy indicators + CPU + Directory + Time + Date
         set -g status-right "#{?client_prefix,#[fg=#1e1e2e,bg=#fab387,bold]  PREFIX  #[fg=#fab387,bg=#1e1e2e],}#{?#{==:#{pane_mode},copy-mode},#[fg=#1e1e2e,bg=#f5c2e7,bold]  COPY  #[fg=#f5c2e7,bg=#1e1e2e],}#[fg=#45475a,bg=#1e1e2e]#[fg=#1e1e2e,bg=#f9e2af]  #{cpu_percentage} #[fg=#f9e2af,bg=#1e1e2e]#[fg=#313244,bg=#1e1e2e]#[fg=#cdd6f4,bg=#313244]  #{b:pane_current_path} #[fg=#1e1e2e,bg=#313244]#[fg=#313244,bg=#1e1e2e] #[fg=#45475a,bg=#1e1e2e]#[fg=#a6adc8,bg=#45475a]  %H:%M #[fg=#89b4fa,bg=#45475a]#[fg=#1e1e2e,bg=#89b4fa]  %d %b #[fg=#89b4fa,bg=#1e1e2e]"

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

        # tmux-thumbs: Copy/paste with keyboard hints
        set -g @thumbs-key 'Space'
        set -g @thumbs-command 'echo -n {} | ~/.local/bin/tmux-copy'
        set -g @thumbs-upcase-command 'echo -n {} | xdg-open'

        # tmux-fzf: FZF integration for tmux
        TMUX_FZF_LAUNCH_KEY="C-f"
        TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"

        # Show fastfetch on session creation
        set-hook -ga session-created 'run-shell "${pkgs.fastfetch}/bin/fastfetch"'
      '';
    };
  };

  # Tmuxinator projects: every export/tmuxinator/*.yml is linked out-of-store so
  # a new project file needs no rebuild and no per-host edit.
  xdg.configFile =
    lib.mapAttrs' (
      name: _:
        lib.nameValuePair "tmuxinator/${name}" {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/export/tmuxinator/${name}";
        }
    )
    (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".yml" name)
      (builtins.readDir ../../../export/tmuxinator));

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
  home.file.".local/bin/tmux-autoreload".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-autoreload";

  # Git autofetch for active pane repo (lightweight alternative to a plugin)
  home.file.".local/bin/tmux-git-autofetch".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-git-autofetch";

  # Simple tmux menus using built-in display-menu
  home.file.".local/bin/tmux-menus".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-menus";

  # Sidebar toggle for file manager (yazi/ranger/lf)
  home.file.".local/bin/tmux-sidebar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-sidebar";

  # Extract items from scrollback and open or copy
  home.file.".local/bin/tmux-extracto".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-extracto";

  # fzf-tmux-url helper script
  home.file.".local/bin/fzf-tmux-url".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/fzf-tmux-url";

  # tmux-fzf-switch helper script (sessions/windows/panes)
  home.file.".local/bin/tmux-fzf-switch".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-fzf-switch";

  # tmux-sessionizer: pick a directory and jump/create a session for it
  home.file.".local/bin/tmux-sessionizer".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-sessionizer";

  # mux-session: declarative tmuxinator sessions by default; resurrect is explicit.
  home.file.".local/bin/mux-session".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/mux-session";

  # tmux-doctor: quick health checks for tmux, tmuxinator, resurrect, clipboard, and k8s.
  home.file.".local/bin/tmux-doctor".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-doctor";

  # tmux-copy: copy stdin to system clipboard and tmux buffer.
  home.file.".local/bin/tmux-copy".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-copy";

  # tmux-paste: read system clipboard with tmux buffer fallback.
  home.file.".local/bin/tmux-paste".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-paste";

  # tmux-kube status snippet: show k8s context/namespace if available
  home.file.".local/bin/tmux-kube".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-kube";

  # tmux-git: show Git branch + short status for active pane path
  home.file.".local/bin/tmux-git".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-git";

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
  home.file.".local/bin/tmux-resurrect-save".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-resurrect-save";

  # Thin wrapper: the resurrect store path is the only Nix-time value the
  # real script needs, so the logic itself lives in system/scripts/tmux-save.
  home.file.".local/bin/tmux-save" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export TMUX_RESURRECT_DIR="${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect"
      exec "$HOME/.dotfiles/system/scripts/tmux-save" "$@"
    '';
  };

  # Thin wrapper: the resurrect store path is the only Nix-time value the
  # real script needs, so the logic itself lives in system/scripts/tmux-restore.
  home.file.".local/bin/tmux-restore" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export TMUX_RESURRECT_DIR="${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect"
      exec "$HOME/.dotfiles/system/scripts/tmux-restore" "$@"
    '';
  };

  home.file.".local/bin/tmux-resume".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-resume";

  # tmux-capture-agents: captura session-ids de agentes por pane (antes de apagar).
  # codex mantiene su rollout-*.jsonl abierto en un fd -> se lee via /proc y se
  # extrae el UUID. Asi podemos hacer "codex resume <uuid>" al restaurar.
  home.file.".local/bin/tmux-capture-agents".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-capture-agents";

  # tmux-restore-agents: corre despues de resurrect. Inyecta "codex resume <uuid>"
  # en cada pane que tenia un codex corriendo. Poll por pane (resurrect es async).
  home.file.".local/bin/tmux-restore-agents".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-restore-agents";

  home.file.".local/bin/tmux-last".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-last";

  # tmux-broadcast: send a command to all SSH panes in current session via popup
  home.file.".local/bin/tmux-broadcast".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/system/scripts/tmux-broadcast";

  home.sessionVariables =
    {
      YAZI_FILE_MANAGER = "yazi";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      FILE_MANAGER = "dolphin";
    };
}
