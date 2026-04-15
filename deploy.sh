#!/bin/bash

sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild switch --flake .#mymbp --impure
