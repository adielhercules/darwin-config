{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    uv
  ];

  # `uv tool install` places binaries in ~/.local/bin, which isn't on PATH
  # by default.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Install headroom-ai globally via uv after every rebuild.
  # `uv tool install` is idempotent — it skips if already installed.
  home.activation.uvInstallHeadroomAi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v uv > /dev/null 2>&1; then
      run uv tool install "headroom-ai[all]"
    fi
  '';
}
