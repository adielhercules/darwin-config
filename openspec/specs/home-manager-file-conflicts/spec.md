### Requirement: .bashrc and .profile are force-overwritten by home-manager
`nix/darwin/home.nix` SHALL set `home.file.".bashrc".force = true;` and
`home.file.".profile".force = true;`, in addition to `programs.bash.enable =
true;`. This is required because on machines migrated from a manual
(pre-Nix) dotfiles setup, `~/.bashrc` and `~/.profile` may already exist as
symlinks pointing at files outside the Nix store (e.g. an old personal
dotfiles repo). Home Manager's `backupFileExtension` mechanism (set to
`"backup"` in `nix/darwin/default.nix`) reliably backs up existing **regular
files** it does not manage (e.g. `.bash_profile`, moved to
`.bash_profile.backup`), but does not reliably back up existing **symlinks**
at those same paths — activation instead fails with "would be clobbered"
unless `force = true` is set for the specific `home.file` entries involved.

#### Scenario: Fresh migration from a manual dotfiles setup
- **WHEN** `~/.bashrc` and/or `~/.profile` exist as symlinks pointing outside
  the Nix store (e.g. to a pre-Nix personal dotfiles repository) and
  `home-manager switch` is run with `programs.bash.enable = true`
- **THEN** activation SHALL succeed, overwriting those paths with the
  Nix-store-managed versions, without requiring manual intervention or a
  `home-manager switch -b backup` flag

#### Scenario: .bash_profile still gets a normal backup
- **WHEN** `~/.bash_profile` exists as a regular (non-symlink) file not
  matching the Nix-store-managed content
- **THEN** activation SHALL move it to `~/.bash_profile.backup` via the
  existing `backupFileExtension` mechanism, since `force` is not set for that
  path and the standard backup path works correctly for regular files
