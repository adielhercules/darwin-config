# Lix requires experimental features to be explicitly enabled
nix_flags := "--extra-experimental-features 'nix-command flakes'"
darwin_rebuild := "/nix/var/nix/profiles/system/sw/bin/darwin-rebuild"

# Selected deployment profile (personal|work), targeting a named flake
# output — see nix/flake.nix. Set automatically by `./init.sh --personal`
# or `./init.sh --work`; do not edit by hand unless you know what you're
# doing. Left as "<not_initialized>" so a `just deploy` run before ever
# running init.sh fails clearly instead of silently deploying nothing/the
# wrong profile.
flake_target := "<not_initialized>"

# List all commands
[private]
default:
  @just --list --unsorted

#
# NixOS specific
#

# Standard deploy
[group('build')]
deploy: && optimise
  sudo {{darwin_rebuild}} switch --flake {{flake_target}} --impure

# Standard deploy with extended debug enabled
[group('build')]
verbose:
  sudo {{darwin_rebuild}} switch --flake {{flake_target}} --impure --show-trace --verbose

# Dry run. Makes it easy to catch errors without generating a new profile
[group('build')]
check:
  sudo {{darwin_rebuild}} check --flake {{flake_target}} --impure

# List all current available generations
[group('info')]
list:
  sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild --list-generations

# Update brew. Remember to redeploy
[group('maintenance')]
update-brew:
  nix {{nix_flags}} flake update homebrew-bundle --flake ./nix
  nix {{nix_flags}} flake update homebrew-cask --flake ./nix
  nix {{nix_flags}} flake update homebrew-core --flake ./nix
  nix {{nix_flags}} flake update homebrew-xcodesorg --flake ./nix

# All steps for full sanitization - as far as Darwin allows
[group('cleanup')]
sanitize-all: check-git-status keep5 gc deploy
#
# Universal commands
#

# Loads up the current flake in the repl
[group('debug')]
repl:
  nix {{nix_flags}} repl -f flake:nixpkgs

# Update flake lock file. Remember to redeploy
[group('maintenance')]
up:
  nix {{nix_flags}} flake update --flake ./nix

# Update flake lock file, fixing unstable to the specified commit. Remember to redeploy. Look at: https://status.nixos.org/ for the current build status
[group('maintenance')]
up-unstable-to hash:
  nix {{nix_flags}} flake lock --update-input nixpkgs-unstable --override-input nixpkgs-unstable github:nixos/nixpkgs/{{hash}}?shallow=1 ./nix
# Update secrets. Remember to redeploy
[group('maintenance')]
up-secrets:
  nix {{nix_flags}} flake update secrets --flake ./nix

# Check if git status is clean before deploying
[private]
check-git-status:
  #!/usr/bin/env bash
  changes=$(git status --porcelain | wc -l)
  if [ 0 -eq $changes ]; then
    exit 0
  else
    echo "Git status is not clean. Please commit or stash your changes before deploying."
    exit 1
  fi

# Commit after updating
[private]
update-commit:
  git add .
  git commit -m "chore: update dependencies"

# Update flake lock file, commit changes and redeploy
[group('maintenance')]
update: check-git-status up update-commit deploy update-comma

# Update comma index information
[group('maintenance')]
update-comma:
  #!/usr/bin/env bash
  filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr A-Z a-z)"
  mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
  wget -q -N https://github.com/nix-community/nix-index-database/releases/latest/download/$filename
  ln -f $filename files

# Optimises store usage
[group('maintenance')]
optimise:
  nix {{nix_flags}} store optimise

# Shows a searcheable dependency tree
[group('info')]
tree:
  nix-tree

# Keep only 5 generations
[group('cleanup')]
keep5:
  sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5

# Remove all generations older than 7 days
[group('cleanup')]
clean:
  sudo nix {{nix_flags}} profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Reclaim unused space after removing older generations. This one is slow to run
[group('cleanup')]
gc:
  sudo nix {{nix_flags}} store gc
  nix {{nix_flags}} store gc
  @printf "\nRemember to run \"deploy\" again to remove old entries from the boot menu\n"

# Prune all other generations and reclaim their space
[group('cleanup')]
[confirm("This will remove all other generations. Are you sure?")]
prune:
  # garbage collect all unused nix store generations
  sudo nix-collect-garbage --delete-old
