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
      "terminal-notifier" # macOS notifications for OpenCode plugin & fish done
      # sketchybar is installed via Homebrew rather than nixpkgs
      # (nix/modules/home/sketchybar) — the nixpkgs-built binary (as of
      # sketchybar v2.23.0, ad-hoc/linker-signed with no entitlements, the
      # standard nixpkgs Darwin build posture) exhibited a total icon-glyph
      # rendering failure that persisted across every diagnosed cause
      # (font-name/cmap verification, font-cache dedup, full logout,
      # explicit --load-font, font swap) and most plausibly traced to that
      # version predating upstream's v2.24.0 "Rendering System Overhaul".
      # Homebrew's tap tracks upstream releases directly, sidestepping this
      # flake's nixpkgs pin entirely. See nix/modules/home/sketchybar/
      # default.nix for the launchd.agents.sketchybar wiring pointed at
      # this Homebrew-installed binary.
      "sketchybar"
    ];
    taps = [
      # Homebrew 6.0+ requires third-party taps to be explicitly trusted
      # before their formulae can be loaded (HOMEBREW_REQUIRE_TAP_TRUST=1
      # by default — a supply-chain hardening measure, since tap contents
      # are executable Ruby, not inert metadata). A one-time manual
      # `brew trust` would NOT persist here: `onActivation.cleanup = "zap"`
      # above runs `brew bundle --cleanup --zap`, which resets Homebrew's
      # trust state to match only what the generated Brewfile declares.
      # Declaring `trusted = true` on the tap itself (rather than on the
      # formula — our `brews` entry above uses the plain "sketchybar" name,
      # not the fully-qualified felixkratz/formulae/sketchybar form, so
      # formula-level trust wouldn't apply) makes this permanent and
      # declarative, surviving every `zap` cleanup.
      {
        name = "felixkratz/formulae";
        trusted = true;
      }
    ];
    casks = [
      "mouseless"
      "ghostty"
      "font-monaspace"
      "alcove"
      "postman"
      "zed"
      "copilot-cli"
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
      # Hides the native macOS menu bar so sketchybar (nix/modules/home/
      # sketchybar) can take over the top of the screen without visual
      # overlap/duplication. NOTE: this legacy key may require a
      # logout/re-login to fully take effect, and on macOS Sonoma+ it can
      # sometimes need to be paired with a one-time manual System Settings
      # toggle (Control Center -> "Automatically hide and show the menu
      # bar: Always") if the key alone doesn't fully suppress the native
      # bar — this is a known OS-level limitation, not something Nix can
      # guarantee.
      _HIHideMenuBar = true;
    };
  };

  # JetBrainsMono Nerd Font is intentionally NOT listed here — it's already
  # installed via stylix.fonts.monospace (nix/darwin/default.nix), which
  # manages it through home-manager's font module. Also declaring it here
  # via nix-darwin's own fonts.packages caused the exact same font
  # family/style set to be registered twice from two independent locations
  # (/Library/Fonts/Nix Fonts/... AND ~/Library/Fonts/HomeManager/...),
  # which led to unpredictable CoreText glyph resolution — icon glyphs in
  # sketchybar rendered blank even though the font/codepoint were
  # confirmed correct via `sketchybar --query`, while plain text (labels)
  # still rendered fine via a fallback font. See sketchybar module's
  # icons.sh for the icon codepoints this was blocking.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    # Hack Nerd Font — sketchybar's own documented default icon font
    # (https://felixkratz.github.io/SketchyBar/setup#fonts), added
    # specifically for icon glyphs in nix/modules/home/sketchybar after
    # JetBrainsMono Nerd Font icons (SF Symbols PUA, then Font Awesome PUA
    # codepoints) both failed to render despite every other diagnostic
    # (font-family match, cmap glyph presence, drawing=on, color contrast,
    # single process, font-cache dedup + full logout) checking out fine —
    # switching to the most battle-tested icon font for this exact use
    # case, plus an explicit --load-font call (see sketchybar/default.nix),
    # isolates whether the issue was JetBrainsMono-build-specific.
    nerd-fonts.hack
  ];
}
