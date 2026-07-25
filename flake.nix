{
  description = "NixOS + nix-darwin dotfiles flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Pin a stable nixpkgs for selectively sourcing known-good packages
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin for macOS
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew management for macOS
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    # Deployment / installer helpers
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    claude-desktop,
    nur,
    disko,
    nixos-facter-modules,
    ...
  } @ inputs: let
    hmStateVersion = "24.05";
  in rec {
    # ============================================
    # home-manager standalone (Nix-on-Ubuntu)
    # ============================================

    # Ubuntu CLI development host via Home Manager
    # Apply: nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev
    homeConfigurations.ubuntu-dev = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs hmStateVersion;};
      modules = [
        ./hosts/ubuntu-dev/home.nix
      ];
    };

    homeConfigurations.ubuntu-cli = homeConfigurations.ubuntu-dev;
    nixosConfigurations.default-msi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs hmStateVersion;};
      modules = [
        ./hosts/main/configuration.nix
        ./hosts/main/msi.nix
        home-manager.nixosModules.default
        {
          nixpkgs.overlays = [nur.overlays.default];
        }
      ];
    };

    nixosConfigurations.default-hp = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs hmStateVersion;};
      modules = [
        ./hosts/main/configuration.nix
        ./hosts/main/hp.nix
        home-manager.nixosModules.default
        {
          nixpkgs.overlays = [nur.overlays.default];
        }
      ];
    };

    nixosConfigurations.default = nixosConfigurations.default-msi;
    nixosConfigurations.main = nixosConfigurations.default-msi;

    # Cloud / installer hosts (formerly deploy/nixos-cloud/flake.nix)
    nixosConfigurations.nixos-aws = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./deploy/nixos-cloud/configuration.nix
        ./deploy/nixos-cloud/disk-config.nix
      ];
    };

    nixosConfigurations.nixos-installer = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./deploy/nixos-cloud/configuration.nix
        ./deploy/nixos-cloud/hardware-configuration.nix
      ];
    };

    # ============================================
    # macOS / nix-darwin configurations
    # ============================================

    darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {inherit inputs hmStateVersion;};
      modules = [
        ./hosts/mac
        home-manager.darwinModules.home-manager
        nix-homebrew.darwinModules.nix-homebrew
        {
          # Homebrew configuration
          nix-homebrew = {
            enable = true;
            enableRosetta = false; # M1 native only
            user = "felipe";
            autoMigrate = true;
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
          };

          # Home Manager configuration
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";
            extraSpecialArgs = {inherit inputs hmStateVersion;};
            users.felipe = import ./hosts/mac/home.nix;
          };
        }
      ];
    };

    # Convenience alias
    darwinConfigurations.default = darwinConfigurations.mac;
  };
}
