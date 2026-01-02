{ self, paths, inputs, nix-darwin, nix-homebrew, nixpkgs, nixpkgs-unstable
, home-manager, ... }:

let
  system = "aarch64-darwin";
  username = "adielhercules";
  rootPath = paths.rootPath;
  nixPath = "${rootPath}/nix";
  files = "${rootPath}/nix/dotfiles";
  pkgs = import nixpkgs { inherit system; };
  lcarsConfig = import ../features.nix { inherit pkgs; };
  specialArgs = {
    inherit self files inputs nixPath username rootPath paths;
    libFiles = "${rootPath}/lib";
    lcars = lcarsConfig.lcars;
  };

in {
  "mymbp" = nix-darwin.lib.darwinSystem {
    modules = [
      ../options/default.nix
      ../features.nix
      # Use application linking from main PR
      { disabledModules = [ "system/applications.nix" ]; }
      "${inputs.nix-darwin-linking}/modules/system/applications.nix"
      # overlays and modules
      {
        nixpkgs.overlays = [
          (final: _prev: {
            unstable =
              import nixpkgs-unstable { inherit (final) system config; };
          })
          (_final: prev: {
            zjstatus = inputs.zjstatus.packages.${prev.system}.default;
          })
        ];
      }
      inputs.stylix.darwinModules.stylix
      nix-homebrew.darwinModules.nix-homebrew
      home-manager.darwinModules.home-manager

      # The main Darwin configuration, now as a module
      ({ lib, pkgs, lcars, ... }: {
        system.primaryUser = username;
        environment.systemPackages = with pkgs; [
          comma
          unstable.devenv
          bat
          curl
          neovim
          lazygit
          nodejs_22
          (lua5_1.withPackages (ps: with ps; [ luarocks ]))
          bun
          vscode
        ];

        environment.shellAliases = {
          klingon = ''say -v Xander "QgaplA"'';
          listening = "lsof -iTCP -sTCP:LISTEN -n -P";
          gitskipped = "git ls-files -v|grep '^S'";
          gitskip = "git update-index --skip-worktree";
          gitunskip = "git update-index --no-skip-worktree";
          gst = "git status";
          gd = "git diff";
          ",," = ", -d ";
        };

        homebrew = {
          enable = true;
          onActivation.cleanup = "zap";
          brews = [ "mas" "xcodes" "aria2" "just" ];
          casks = [
            "mouseless"
            "ghostty"
            "raycast"
            "leader-key"
            "font-monaspace"
            "alcove"
            "postman"
            "herd"
          ];
          # masApps = { "Tomito" = 1526042938; };
        };

        system.defaults = {
          controlcenter.BatteryShowPercentage = true;
          # dock.autohide = true;
          finder = {
            _FXSortFoldersFirst = true;
            AppleShowAllExtensions = true;
            AppleShowAllFiles = true;
            FXDefaultSearchScope = "SCcf";
            FXEnableExtensionChangeWarning = false;
            FXPreferredViewStyle = "clmv";
            NewWindowTarget = "Home";
            QuitMenuItem = true;
            ShowPathbar = true;
            ShowStatusBar = true;
          };
          loginwindow.GuestEnabled = false;
          NSGlobalDomain = {
            AppleICUForce24HourTime = true;
            AppleInterfaceStyle = "Dark";
          };
        };

        fonts.packages = with pkgs; [
          nerd-fonts.fira-code
          nerd-fonts.jetbrains-mono
        ];

        security = {
          # pki.certificateFiles = [ "/etc/ssl/certs/corporate.crt" ];
          pam.services.sudo_local.touchIdAuth = true;
        };

        nix.settings.experimental-features = "nix-command flakes";
        programs.fish.enable = lcars.shell.fish.enable;

        system.configurationRevision =
          if (self ? rev) then self.rev else self.dirtyRev;
        system.stateVersion = 6;
        nixpkgs.hostPlatform = system;
        nixpkgs.config.allowUnfree = true;

        stylix = {
          enable = true;
          polarity = "dark";
          base16Scheme = "${files}/lcars.yaml";
          fonts = {
            monospace = {
              package = pkgs.nerd-fonts.jetbrains-mono;
              name = "JetBrainsMono Nerd Font";
            };
          };
        };

        users = {
          knownUsers = [ username ];
          users.${username} = lib.mkMerge [
            {
              home = "/Users/${username}";
              name = "${username}";
              uid = 501;
            }
            (lib.mkIf lcars.shell.fish.enable { shell = lcars.shell.fish.pkg; })
          ];
        };

        nix = {
          enable = true;
          package = pkgs.nix;
          extraOptions = ''
            experimental-features = nix-command flakes
          '';
        };
      })

      # Home-manager user configuration
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import "${nixPath}/darwin/home.nix";
        home-manager.extraSpecialArgs = inputs // specialArgs;
        home-manager.backupFileExtension = "backup";
      }
    ];

    specialArgs = specialArgs;
  };
}
