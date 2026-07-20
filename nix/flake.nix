{
  description = "Adiel Nix-Darwin system flake";

  inputs = {
    # Base packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Global styling through stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom
    devenv = {
      url = "github:cachix/devenv/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Darwin specific
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Enable homebrew management through nix
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      inputs.nixpkgs.follows = "nixpkgs";
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
        rootPath = self;
      };
      configs = import ./darwin {
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
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild switch --flake .
      #
      # Profile selection is automatic: `darwinConfigurations` is keyed by
      # each machine's `scutil --get LocalHostName` value (see
      # `hostProfiles` in `nix/darwin/default.nix`), and `darwin-rebuild`'s
      # built-in hostname-based resolution picks the matching attribute for
      # the machine it's run on when no `#attr` suffix is given. An explicit
      # override remains available via `--flake ".#<hostname>"`, e.g.
      # `--flake ".#MPCE-MBP-RWF4347WJP"`.
      # `configs.pkgs` exposes the shared package set (identical overlays
      # across both profiles) as `self.darwinConfigurations.pkgs`, for
      # tooling/`nix repl` convenience only — it has no effect on which
      # profile's modules are built.
      darwinConfigurations = configs // {
        pkgs = configs."Adiels-MacBook-Pro".pkgs;
      };

      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
      };
    };
}
