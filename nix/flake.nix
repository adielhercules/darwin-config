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
    nix-darwin-linking = {
      url = "github:nix-darwin/nix-darwin/pull/1396/head";
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
    # Workaround for absolute path requirements
    paths.url = "path:./paths";
  };

  outputs = inputs@{ self, paths, nixpkgs, nixpkgs-unstable, home-manager
    , nix-darwin, homebrew-bundle, homebrew-cask, homebrew-core
    , homebrew-xcodesorg, nix-homebrew, ... }: {
      # Disable nix management from nix-darwin to avoid determinate conflict
      nix.enable = false;

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
