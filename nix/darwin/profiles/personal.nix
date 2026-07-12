# Personal-only additions. Appends to profiles/defaults.nix — never repeats
# shared entries.
{ ... }: {
  homebrew.casks = [ "herd" ];
}
