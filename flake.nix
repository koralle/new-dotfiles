{
  description = "koralle's Nix Flakes";

  inputs = {
    # nixpkgs-unstable
    # https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    # nix-darwin
    # https://github.com/nix-darwin/nix-darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager
    # https://github.com/nix-community/home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # neovim-nightly-overlay
    # https://github.com/nix-community/neovim-nightly-overlay
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-homebrew
    # https://github.com/zhaofengli/nix-homebrew
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # homebrew-core
    # https://github.com/Homebrew/homebrew-core
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    # homebrew-cask
    # https://github.com/Homebrew/homebrew-cask
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # nikitabobko/homebrew-tap (Aerospace)
    # https://github.com/nikitabobko/homebrew-tap
    homebrew-tap = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-tap,
      home-manager,
      ...
    }:
    let
      username = "koralle";
      system = "aarch64-darwin";
    in
    {
      darwinConfigurations."koralle-macbookair" = nix-darwin.lib.darwinSystem {
        inherit system;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };

        specialArgs = {
          inherit username;
        };

        modules = [
          ./src/nix/hosts/koralle-macbookair

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = username;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "nikitabobko/homebrew-tap" = homebrew-tap;
              };
              mutableTaps = true;

              trust = {
                taps = [
                  "docker/tap"
                  "caezium/tap"
                  "tursodatabase/tap"
                ];
              };
            };
          }

          (
            { config, ... }:
            {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
            }
          )

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs username;
            };
            home-manager.users.${username} = import ./src/nix/modules/flake.nix;
          }
        ];
      };
    };
}
