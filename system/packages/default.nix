{
  pkgs,
  inputs,
}: {
  # Development tools and programming languages
  development = import ./development.nix {inherit pkgs;};

  # Desktop applications and user-facing software
  desktop = import ./desktop.nix {inherit pkgs inputs;};

  # User-specific packages managed by Home Manager
  user = import ./user.nix {inherit pkgs;};

  # Convenience functions to get combined package lists
  systemPackages =
    (import ./system.nix {inherit pkgs;})
    ++ (import ./development.nix {inherit pkgs;})
    ++ (import ./desktop.nix {inherit pkgs inputs;});

  userPackages = import ./user.nix {inherit pkgs;};
}
