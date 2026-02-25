# Homebrew configuration for macOS
# GUI apps that can't be installed via Nix
{
  config,
  lib,
  ...
}: {
  # Homebrew packages managed declaratively
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall"; # Remove unlisted packages
      upgrade = true;
    };

    # Taps
    taps = [
      "nikitabobko/tap"
      "anomalyco/tap"
    ];
    # CLI tools via Homebrew
    brews = [
      "ncdu" # Disk usage analyzer
      "pam-reattach"
      "nmap"
      "go"
      "node"
      "opencode"
      "awscli"
      "azure-cli"
      "ffmpeg"
    ];

    # GUI apps via Cask (can't be installed via Nix)
    casks = [
      # === Remote Work (Satellite Strategy) ===
      "moonlight" # Stream from main NixOS workstation
      "codex"
      "steam"
      "heroic" # Epic Games launcher
      "crossover" # Windows compatibility layer
      "microsoft-teams" # Video conferencing and collaboration
      # tailscale - installed manually via official installer
      "antigravity"
      # === Terminals & Development ===
      "kitty"
      "ghostty"
      "visual-studio-code" # For when Neovim isn't enough
      "cursor" # AI-powered code editor
      "dbeaver-community" # Database management tool

      # === Browsers ===
      "brave-browser"
      "google-chrome"
      "firefox@developer-edition"
      "zen"
      "helium-browser"

      # === Window Management ===
      "aerospace" # i3/Hyprland-style tiling WM (no accessibility permissions needed)

      # === Utilities ===
      "macfuse" # FUSE for macOS — required for rclone mount
      "shortcat" # Vimium-style keyboard hints for all of macOS
      "raycast" # Spotlight replacement (like Rofi on Linux)
      "bruno" # Open-source API client (Postman alternative)
      "keycastr" # Show keypresses on screen (for screen recordings)
      "stats" # Menu bar system monitor
      "aldente" # Battery management (important for M1 longevity)
      "karabiner-elements" # Advanced keyboard remapping
      "hiddenbar" # Hide menu bar icons
      "warp"
      "scroll-reverser"
      "appcleaner"
      "1password" # Password manager
      "freedom" # Distraction blocker

      # === Containers ===
      "orbstack" # Docker/Linux VM (lightweight alternative to Docker Desktop)

      # === Media ===
      "iina" # Video player
      "obs" # Streaming and recording
      "betterdisplay"
      # DaVinci Resolve requires manual download from blackmagicdesign.com

      # === Productivity ===
      "obsidian" # Note-taking
      "zed" # Code editor
      "caffeine"
      "antinote"
      "activitywatch" # Time tracking and productivity monitoring
      "claude" # Claude Desktop AI assistant

      # === Design ===
      # "affinity-designer" # Vector graphics editor
      "affinity-photo" # Photo editing
      # "affinity-publisher" # Desktop publishing
      "canva" # Design tool
      # capcut self-updates outside Homebrew - manage manually

      # === File Sharing ===
      "localsend" # Local file transfer
      "nextcloud" # Cloud sync
      # "filezilla" # FTP/SFTP client - cask unavailable, install manually if needed
    ];

    # Mac App Store apps (requires being signed in to App Store)
    masApps = {
      # Uncomment if needed - requires `mas` CLI
      # "Xcode" = 497799835;  # Only if doing iOS dev
      # "Tailscale" = 1475387142;  # Alternative to cask
    };
  };
}
