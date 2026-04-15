{
  description = "Adiel Nix-Darwin system flake";

  inputs = {
    # Base packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Global styling through stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom
    devenv.url = "github:cachix/devenv/latest";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Darwin specific
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Enable homebrew management through nix
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-xcodesorg = {
      url = "github:xcodesorg/homebrew-made";
      flake = false;
    };

    zjstatus = { url = "github:dj95/zjstatus"; };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, nix-darwin
    , homebrew-bundle, homebrew-cask, homebrew-core, homebrew-xcodesorg
    , nix-homebrew, ... }:
    let paths = { rootPath = "/Users/adielhercules/darwin-config"; };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations = (import ./darwin {
        inherit self inputs nix-darwin nixpkgs nixpkgs-unstable nix-homebrew
          home-manager homebrew-bundle homebrew-cask homebrew-core
          homebrew-xcodesorg paths;
      });

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mymbp".pkgs;
    };
}
