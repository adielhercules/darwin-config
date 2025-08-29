{
  description = "Adiel Nix-Darwin system flake";

  inputs = {
    # Base packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom
    devenv.url = "github:cachix/devenv/latest";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable?shallow=1";

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
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew?shallow=1";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle?shallow=1";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask?shallow=1";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core?shallow=1";
      flake = false;
    };
    homebrew-xcodesorg = {
      url = "github:xcodesorg/homebrew-made?shallow=1";
      flake = false;
    };

    # Workaround for absolute path requirements
    paths.url = ./paths;
  };

  /*
outputs = inputs@{ self, paths, nix-darwin, nixpkgs, nixpkgs-unstable, home-manager
    , homebrew-bundle, homebrew-cask, homebrew-core
    , homebrew-xcodesorg, nix-homebrew, ... }: {
      configuration = (import ./config {
        inherit self inputs nixpkgs nixpkgs-unstable nix-homebrew
          home-manager homebrew-bundle homebrew-cask homebrew-core
          homebrew-xcodesorg paths;
      });
    };
}
  */

  outputs = inputs@{ self, paths, nixpkgs, nixpkgs-unstable, home-manager
    , nix-darwin, homebrew-bundle, homebrew-cask, homebrew-core
    , homebrew-xcodesorg, nix-homebrew, ... }: {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations = (import ./darwin {
      inherit self inputs nix-darwin nixpkgs nixpkgs-unstable nix-homebrew
          home-manager homebrew-bundle homebrew-cask homebrew-core
          homebrew-xcodesorg paths;
    });

    # Expose the package set, including overlays, for convenience.
    #darwinPackages = self.darwinConfigurations."mymbp".pkgs;
  };

  /**

let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
	ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
	pkgs.mkalias
	pkgs.neovim
        ];
      

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."mymbp" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    #darwinPackages = self.darwinConfigurations."mymbp".pkgs;
  };
  */
}
