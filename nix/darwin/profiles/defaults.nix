# Shared defaults for all profiles.
#
# All entries here are common to both `personal` and `work` machines.
# Per-profile modules (`personal.nix`, `work.nix`) only ever ADD to these
# lists — never repeat or replace them. Nix-darwin deep-merges list-typed
# options (`homebrew.brews`, `homebrew.casks`, `environment.systemPackages`,
# etc.) across all merged modules, so appends from any profile module
# accumulate automatically.
{ pkgs, ... }:
{
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
  ];

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    global = {
      autoUpdate = true;
      brewfile = true;
    };

    brews = [
      "mas"
      "xcodes"
      "aria2"
      "just"
      "opencode"
      "yazi"
      "rtk"
    ];
    taps = [ ];
    casks = [
      "mouseless"
      "ghostty"
      "font-monaspace"
      "alcove"
      "postman"
      "zed"
    ];
    masApps = { };
  };

  system.defaults = {
    controlcenter.BatteryShowPercentage = true;
    dock.autohide = true;
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
}
