{ lib, pkgs, ... }:
{
  # Install/update OpenCode v2 (beta) via bun, since it's not yet
  # available as a Homebrew formula. Runs on every rebuild so the
  # `opencode2` binary stays current with the `next` beta tag.
  # OpenCode v2 installs as `opencode2` and does not replace the
  # Homebrew-installed `opencode` v1 binary (see opencode.nix).
  #
  # Uses the Nix store path directly rather than `command -v bun` /
  # bare `bun`, because home-manager's activation script runs with its
  # own hardcoded minimal PATH that does not include
  # `/run/current-system/sw/bin` — a PATH-based lookup silently no-ops.
  home.activation.installOpencode2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.bun}/bin/bun install -g --trust @opencode-ai/cli@next
  '';
}
