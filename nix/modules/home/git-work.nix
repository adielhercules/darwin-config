# Work-profile git identity — placeholders only. Update with your real
# corporate name/email before relying on git commits made under the work
# profile (a build-time warning fires below until you do).
{ lib, ... }:
let
  name = "<work-name-required>";
  email = "<work-email-required>";
in {
  programs.git.settings.user = { inherit name email; };

  warnings = lib.optional (name == "<work-name-required>"
    || email == "<work-email-required>") ''
      profile=work git user.name/email are still placeholders in
      nix/modules/home/git-work.nix — update them with your real corporate
      identity before making commits under this profile.
    '';
}
