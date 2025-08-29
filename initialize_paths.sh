#!/run/current-system/sw/bin/bash

{ 
  echo "{ outputs = { ... }: { rootPath = \"$PWD\"; }; }"
} > ./paths/flake.nix

# This marks the file to be skipped in the worktree. Effectively ignoring changes to it.
#git update-index --skip-worktree ./paths/flake.nix
