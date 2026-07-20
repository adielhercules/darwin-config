# Personal-only additions. Appends to profiles/defaults.nix — never repeats
# shared entries.
_: {
  homebrew.casks = [ "herd" ];
  homebrew.brews = [
    "glow"
    "xcodegen"
  ];
}
