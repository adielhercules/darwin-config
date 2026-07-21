{
  self,
  paths,
  inputs,
  nix-darwin,
  nix-homebrew,
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  ...
}:

let
  system = "aarch64-darwin";
  username =
    let
      sudoUser = builtins.getEnv "SUDO_USER";
      envUser = builtins.getEnv "USER";
    in
    if sudoUser != "" then
      sudoUser
    else if envUser != "" then
      envUser
    else
      builtins.abort "ERROR: Cannot determine username. Neither SUDO_USER nor USER environment variable is set.";
  inherit (paths) rootPath;
  nixPath = rootPath + "/nix";
  files = rootPath + "/../config";
  pkgs = import nixpkgs { inherit system; };
  lcarsConfig = import ../features.nix { inherit pkgs; };

  mkDarwinConfig =
    profile:
    assert nixpkgs.lib.assertMsg (builtins.elem profile [
      "personal"
      "work"
    ]) "Unknown darwin profile '${profile}': expected one of \"personal\" or \"work\".";
    nix-darwin.lib.darwinSystem {
      modules = mkModules profile;
      specialArgs = mkSpecialArgs profile;
    };

  mkSpecialArgs = profile: {
    inherit
      self
      files
      inputs
      nixPath
      username
      rootPath
      paths
      profile
      ;
    libFiles = rootPath + "/lib";
    inherit (lcarsConfig) lcars;
  };

  # Keyed by `scutil --get LocalHostName` (the value darwin-rebuild's
  # built-in hostname-based flake-attr resolution actually reads) — NOT the
  # mDNS/Bonjour `.local`-suffixed name returned by `hostname`.
  hostProfiles = {
    "Adiels-MacBook-Pro" = "personal";
    "MPCE-MBP-RWF4347WJP" = "work";
  };

  mkModules = profile: [
    ../options/default.nix
    ../features.nix
    ../darwin/profiles/defaults.nix
    (../darwin/profiles + "/${profile}.nix")
    # overlays and modules
    {
      nixpkgs.overlays = [
        (final: _prev: {
          unstable = import nixpkgs-unstable {
            inherit (final) config;
            system = final.stdenv.hostPlatform.system;
          };
        })
        (_final: prev: {
          zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
        })
      ];
    }
    inputs.stylix.darwinModules.stylix
    nix-homebrew.darwinModules.nix-homebrew
    home-manager.darwinModules.home-manager

    # The main Darwin configuration, now as a module
    (
      {
        pkgs,
        lcars,
        ...
      }:
      {
        system = {
          primaryUser = username;
          configurationRevision = if (self ? rev) then self.rev else self.dirtyRev;
          stateVersion = 6;
        };

        environment.shellAliases = {
          klingon = ''say -v Xander "QgaplA"'';
          listening = "lsof -iTCP -sTCP:LISTEN -n -P";
          gitskipped = "git ls-files -v|grep '^S'";
          gitskip = "git update-index --skip-worktree";
          gitunskip = "git update-index --no-skip-worktree";
          gst = "git status";
          gd = "git diff";
          gl = "git pull";
          gpsup = "git push --set-upstream";
          gco = "git checkout";
          ",," = ", -d ";
        };

        security = {
          # Corporate certificates are auto-discovered from
          # ~/.config/darwin-secrets/ for the work profile — see
          # profiles/work.nix.
          # pki.certificateFiles = [ "/etc/ssl/certs/corporate.crt" ];
          pam.services.sudo_local.touchIdAuth = true;
        };

        nix.settings.experimental-features = "nix-command flakes";
        programs.fish.enable = lcars.shell.fish.enable;

        nixpkgs.hostPlatform = system;
        nixpkgs.config.allowUnfree = true;

        stylix = {
          enable = true;
          polarity = "dark";
          base16Scheme = "${files}/stylix/lcars.yaml";
          fonts = {
            monospace = {
              package = pkgs.nerd-fonts.jetbrains-mono;
              name = "JetBrainsMono Nerd Font";
            };
          };
        };

        users = {
          knownUsers = [ username ];
          users.${username} = {
            home = "/Users/${username}";
            name = "${username}";
            uid =
              let
                sudoUid = builtins.getEnv "SUDO_UID";
              in
              if sudoUid != "" then
                builtins.fromJSON sudoUid
              else
                builtins.abort "ERROR: SUDO_UID not set. Run via sudo (e.g. `just deploy`).";
            # Login shell intentionally left as macOS default (/bin/zsh).
            # Fish is launched directly by Ghostty via its `command` setting,
            # using the stable home-manager path that doesn't depend on
            # /run/current-system being set up before login.
          };
        };

        # Disable nix management from nix-darwin - Lix manages its own daemon
        nix.enable = false;

        # Add logging to the activate-system boot daemon so failures are visible
        launchd.daemons.activate-system.serviceConfig = {
          StandardOutPath = "/var/log/nix-darwin-activate.log";
          StandardErrorPath = "/var/log/nix-darwin-activate.log";
        };
      }
    )

    # Home-manager user configuration
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = import ./home.nix;
        extraSpecialArgs = inputs // (mkSpecialArgs profile);
        backupFileExtension = "backup";
      };
    }
  ];
in
nixpkgs.lib.mapAttrs (_hostname: mkDarwinConfig) hostProfiles
