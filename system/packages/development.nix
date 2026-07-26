{pkgs}:
# Development tools and programming languages
with pkgs; [
  # Version Control & Development Tools
  git
  git-crypt # Git encryption tool
  lazygit # Terminal UI for git
  act # GitHub Actions locally
  resumed # Resume management
  devbox
  ansible
  docker
  alejandra # Nixos text formatter
  insomnia # API testing tool
  fabric-ai # AI CLI tool
  crush # AI coding agent (was nur.repos.charmbracelet.crush; now in nixpkgs)
  aider-chat # AI pair programming assistant
  doppler # Environment management
  infisical # Centralized secret management (ai-env backend)
  atuin
  nixos-anywhere #
  # ollama

  # heroku

  curlie # User-friendly curl
  lorri # Nix shell automation
  fswatch # File system watchin

  # Programming Languages & Runtimes
  python3
  python3Packages.jupyter
  python3Packages.pip
  # lm_sensors
  # stable-diffusion
  # python3Packages.pytorch
  # python3Packages.transformers
  # python3Packages.tensorflow
  # python3Packages.scikit-learn
  # python3Packages.pandas
  # python3Packages.numpy
  # python3Packages.matplotlib
  # python3Packages.jupyter
  # python3Packages.ipython
  nodejs_22
  go

  # Electronics
  # esptool

  # Text Editors
  neovim
  zed-editor

  # Security
  # clamav

  # Build Tools & Package Managers
  gcc
  # pulumi-bin
  # windsurf
  # k3s
  # k3sup
  # nodejs
  # nodePackages.typescript
  # nodePackages.anthropic-ai/claude-code
]
