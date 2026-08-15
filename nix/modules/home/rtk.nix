{ lib, ... }:
{
  # Run rtk init after every rebuild to keep AI tool hooks up to date.
  # Both commands are idempotent.
  #
  # Uses the absolute Homebrew path directly rather than `command -v rtk`,
  # because home-manager's activation script runs with its own hardcoded
  # minimal PATH that does not include `/opt/homebrew/bin` — a PATH-based
  # lookup silently no-ops instead of erroring, hiding the failure.
  home.activation.rtkInitOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x /opt/homebrew/bin/rtk ]; then
      run /opt/homebrew/bin/rtk init -g --opencode --auto-patch
    fi
  '';

  home.activation.rtkInitCopilot = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x /opt/homebrew/bin/rtk ]; then
      run /opt/homebrew/bin/rtk init -g --copilot --auto-patch
    fi
  '';
}
