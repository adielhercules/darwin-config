# Work-only additions. Appends to profiles/defaults.nix — never repeats
# shared entries.
#
# Also conditionally imports an external, non-committed secrets file for
# corporate certificates / proxy / VPN settings. See work.nix.example for
# the expected shape, and the comment below for the auto-discovery
# convention.
{ lib, ... }:
let
  # NOTE: hardcoded to match the single-user convention used elsewhere in
  # this repo (see `username` in darwin/default.nix).
  secretsDir = "/Users/adielhercules/.config/darwin-secrets";
  secretsFile = "${secretsDir}/work.nix";
  hasSecrets = builtins.pathExists secretsFile;

  # Auto-discover any .crt/.pem files dropped into the same directory and
  # feed them into security.pki.certificateFiles — no per-file registration
  # needed in this repo, just place the file and rebuild.
  #
  # To add secrets/certs:
  #   1. mkdir -p ~/.config/darwin-secrets
  #   2. Copy your real work.nix (see work.nix.example for the shape) into
  #      that directory.
  #   3. Drop any corporate .crt/.pem certificate files into the same
  #      directory — they are picked up automatically, no Nix changes needed.
  #   4. Re-run `darwin-rebuild switch --flake ".#work" --impure`.
  certFiles = if builtins.pathExists secretsDir then
    map (name: "${secretsDir}/${name}") (builtins.attrNames
      (lib.filterAttrs (name: type:
        type == "regular"
        && (lib.hasSuffix ".crt" name || lib.hasSuffix ".pem" name))
        (builtins.readDir secretsDir)))
  else
    [ ];
in {
  homebrew.casks = [ "visual-studio-code" ];

  imports = lib.optional hasSecrets secretsFile;

  security.pki.certificateFiles = certFiles;

  warnings = lib.optional (!hasSecrets) ''
    profile=work but no secrets file found at ${secretsFile} — corporate certs/proxy config will be missing.
    See nix/darwin/profiles/work.nix.example for the expected shape, and drop the real file (plus any
    .crt/.pem certificates) into ${secretsDir}/.
  '';
}
