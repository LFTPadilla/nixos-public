# MacBook Pro - Satellite workstation configuration
# Setup optimized for remote work with main NixOS rig
{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./homebrew.nix
  ];

  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-jobs = "auto";
      cores = 0; # Use all cores
      # Use binary caches aggressively to avoid compilation
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    # Garbage collection
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 14d";
    };
  };

  # System packages (CLI tools via Nix - lightweight focus)
  # Most dev tools are in home.nix; browsers via Homebrew casks
  environment.systemPackages = with pkgs; [
    # Core utilities
    coreutils
    gnused
    gawk
    findutils

    # Development essentials
    git
    git-crypt
    gh

    # Remote work (satellite strategy - connect to main NixOS rig)
    mosh

    # Shell tools
    zsh
    claude-code

    # System monitoring (lightweight)
    htop
    bottom

    # Nix tools
    nil # Nix LSP
    nixfmt
    alejandra
  ];

  # Tailscale for VPN to main workstation
  # Disabled - using Homebrew GUI app instead
  # services.tailscale.enable = true;

  # System settings
  system = {
    stateVersion = 5;

    # Keyboard settings
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true; # Essential for Vim/terminal
    };

    defaults = {
      # Global settings
      NSGlobalDomain = {
        AppleKeyboardUIMode = 3; # Full keyboard control
        ApplePressAndHoldEnabled = false; # Key repeat instead of accent menu
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        # AppleInterfaceStyle not set — managed manually via `tt` alias
        AppleShowScrollBars = "WhenScrolling";
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        NSTableViewDefaultSizeMode = 2; # Medium sidebar icon size
        "com.apple.swipescrolldirection" = true; # Natural scrolling
        "com.apple.trackpad.scaling" = 3.0; # Trackpad speed (0.0 to 3.0)
        "com.apple.trackpad.forceClick" = true; # Force click enabled
        "com.apple.springing.enabled" = true; # Spring loading for folders
        "com.apple.springing.delay" = 0.5;
      };

      # Dock settings
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.2;
        show-recents = false;
        tilesize = 48;
        largesize = 112; # Magnification size
        magnification = true;
        orientation = "bottom";
        mineffect = "scale"; # Minimize effect
        minimize-to-application = true;
        launchanim = false; # Disable launch bounce animation
        mru-spaces = false; # Don't rearrange spaces
        expose-animation-duration = 0.1;
        expose-group-apps = true; # Group windows by app in Mission Control
        show-process-indicators = true;
        # Hot corners (values: 1=disabled, 2=Mission Control, 3=App Windows, 4=Desktop, 11=Launchpad, 12=Notification Center)
        wvous-tl-corner = 2; # Top-left: Mission Control
        wvous-tr-corner = 12; # Top-right: Notification Center
        wvous-bl-corner = 11; # Bottom-left: Launchpad
        wvous-br-corner = 3; # Bottom-right: App Windows
      };

      # Finder settings (only nix-darwin supported options)
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv"; # List view
        _FXShowPosixPathInTitle = true;
        QuitMenuItem = true; # Allow quitting Finder
      };

      # Trackpad (only nix-darwin supported options)
      trackpad = {
        Clicking = true; # Tap to click
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false; # Disabled to allow 3-finger gestures
      };

      # Screenshots
      screencapture = {
        location = "~/Pictures/Screenshots";
        type = "png";
        disable-shadow = true;
      };

      # Spaces
      spaces.spans-displays = false; # Spaces are per-display

      # Menu bar clock
      menuExtraClock = {
        Show24Hour = true;
        ShowSeconds = false;
      };

      # Custom preferences (for options not directly supported by nix-darwin)
      CustomUserPreferences = {
        # Global domain extras
        NSGlobalDomain = {
          AppleReduceDesktopTinting = true;
          AppleEnableSwipeNavigateWithScrolls = true; # Two finger swipe between pages
        };
        # Trackpad gestures (built-in trackpad)
        "com.apple.AppleMultitouchTrackpad" = {
          FirstClickThreshold = 0; # Light click
          SecondClickThreshold = 0; # Light force click
          ActuationStrength = 1; # Haptic feedback strength
          # Three finger vertical: Mission Control (up) / App Exposé (down)
          TrackpadThreeFingerVertSwipeGesture = 2;
          # Three finger horizontal: switch full-screen apps/spaces
          TrackpadThreeFingerHorizSwipeGesture = 2;
          # Two finger swipe from right edge: Notification Center
          TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
          # Thumb + three fingers spread: Show Desktop
          TrackpadFourFingerPinchGesture = 2;
          # Two finger gestures
          TrackpadTwoFingerDoubleTapGesture = 1; # Smart zoom
        };
        # Bluetooth Magic Trackpad (same settings)
        "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
          TrackpadThreeFingerVertSwipeGesture = 2;
          TrackpadThreeFingerHorizSwipeGesture = 2;
          TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
          TrackpadFourFingerPinchGesture = 2;
          TrackpadTwoFingerDoubleTapGesture = 1;
        };
        # Dock gesture settings
        "com.apple.dock" = {
          showMissionControlGestureEnabled = true;
          showAppExposeGestureEnabled = true;
          showDesktopGestureEnabled = true;
        };
        # Window manager (Stage Manager settings)
        "com.apple.WindowManager" = {
          GloballyEnabled = false; # Stage Manager disabled
          EnableStandardClickToShowDesktop = false;
          StandardHideDesktopIcons = true;
          HideDesktop = true;
          StandardHideWidgets = true;
        };
        # Don't write .DS_Store on network/USB volumes
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        # Finder extras (options not in system.defaults.finder)
        "com.apple.finder" = {
          ShowPreviewPane = true;
          FXDefaultSearchScope = "SCcf"; # Search current folder by default
          _FXSortFoldersFirst = false;
          FXRemoveOldTrashItems = true; # Remove items from Trash after 30 days
          WarnOnEmptyTrash = false;
          ShowExternalHardDrivesOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          ShowHardDrivesOnDesktop = false;
          NewWindowTarget = "PfHm"; # New windows open to home
        };
      };
    };

    # Activation script (runs as root)
    activationScripts.postActivation.text = ''
      # Create directories for user
      sudo -u felipe mkdir -p /Users/felipe/Pictures/Screenshots
      sudo -u felipe mkdir -p /Users/felipe/Developer

      # Disable Spotlight indexing for dev directories (ignore errors)
      mdutil -i off /Users/felipe/Developer &>/dev/null || true
    '';
  };

  # Security - Touch ID for sudo (including tmux support)
  security.pam.services.sudo_local = {
    touchIdAuth = true; # Enable Touch ID for sudo
    reattach = true; # Enable pam_reattach for tmux support
  };

  # Programs
  programs = {
    zsh.enable = true;
    nix-index.enable = true;
  };

  # Fonts (matching NixOS setup)
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    fira-code
  ];

  # User
  users.users.felipe = {
    name = "felipe";
    home = "/Users/felipe";
    shell = pkgs.zsh;
  };

  # Primary user for user-specific options
  system.primaryUser = "felipe";

  nixpkgs.config.allowUnfree = true;

  # Networking
  networking.hostName = "mac";

  # Custom hosts
  environment.etc."hosts".text = ''
    127.0.0.1 localhost
    255.255.255.255 broadcasthost
    ::1             localhost
    ${import ../../system/private-hosts.nix}
  '';

  # Environment variables (system-wide, applies during activation)
  environment.variables = {
    # Prevent git from searching into nix store during brew bundle
    GIT_CEILING_DIRECTORIES = "/nix";
  };
}
