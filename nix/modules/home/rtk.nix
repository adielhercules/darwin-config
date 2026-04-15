{ lib, ... }:

{
  # Run rtk init after every rebuild to keep AI tool hooks up to date.
  # Both commands are idempotent. The `command -v rtk` guard makes the
  # activation a safe no-op if Homebrew hasn't put rtk on PATH yet
  # (e.g. on first boot), and it self-heals on the next rebuild.

  home.activation.rtkInitOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v rtk > /dev/null 2>&1; then
      run rtk init -g --opencode --auto-patch
    fi
  '';

  home.activation.rtkInitCopilot = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v rtk > /dev/null 2>&1; then
      run rtk init -g --copilot --auto-patch
    fi
  '';
}
