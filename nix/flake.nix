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

    zjstatus = {
      url = "github:dj95/zjstatus";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-darwin,
      homebrew-bundle,
      homebrew-cask,
      homebrew-core,
      homebrew-xcodesorg,
      nix-homebrew,
      ...
    }:
    let
      paths = {
        rootPath = "/Users/adielhercules/darwin-config";
      };
      configs = (
        import ./darwin {
          inherit
            self
            inputs
            nix-darwin
            nixpkgs
            nixpkgs-unstable
            nix-homebrew
            home-manager
            homebrew-bundle
            homebrew-cask
            homebrew-core
            homebrew-xcodesorg
            paths
            ;
        }
      );
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild switch --flake ".#personal"
      # $ darwin-rebuild switch --flake ".#work"
      #
      # Profile selection is always explicit — there is no bare `--flake .`
      # target and no hostname-based auto-resolution. `configs.pkgs` exposes
      # the shared package set (identical overlays across both profiles) as
      # `self.darwinConfigurations.pkgs`, for tooling/`nix repl` convenience
      # only — it has no effect on which profile's modules are built.
      darwinConfigurations = configs // {
        pkgs = configs.personal.pkgs;
      };

      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
    };
}
