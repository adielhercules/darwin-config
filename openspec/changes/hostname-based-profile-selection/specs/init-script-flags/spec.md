## REMOVED Requirements

### Requirement: init.sh accepts --personal flag
**Reason**: Profile selection is now automatic via hostname-based `darwinConfigurations` resolution (see `split-profiles` spec); a manual `--personal` override is no longer needed since `just deploy`/`darwin-rebuild switch --flake .` always resolves the correct profile for the current machine.
**Migration**: Run `init.sh --deploy` (now functional) or `just deploy` directly — no profile flag required. If manually targeting the personal profile on a different machine is ever needed, use `darwin-rebuild switch --flake ".#Adiels-MacBook-Pro"` directly.

### Requirement: init.sh accepts --work flag
**Reason**: Profile selection is now automatic via hostname-based `darwinConfigurations` resolution (see `split-profiles` spec); a manual `--work` override is no longer needed since `just deploy`/`darwin-rebuild switch --flake .` always resolves the correct profile for the current machine.
**Migration**: Run `init.sh --deploy` (now functional) or `just deploy` directly — no profile flag required. If manually targeting the work profile on a different machine is ever needed, use `darwin-rebuild switch --flake ".#MPCE-MBP-RWF4347WJP"` directly.

## MODIFIED Requirements

### Requirement: init.sh --deploy flag performs a real deploy
`init.sh` SHALL accept a `--deploy` flag that invokes `just deploy` to perform `darwin-rebuild switch`, relying on hostname-based auto-resolution to select the correct profile. This flag SHALL NOT fail or require any profile flag, since profile-less deploy is now the standard, always-correct path.

#### Scenario: --deploy flag performs a real deploy
- WHEN the user runs `init.sh --deploy`
- THEN `just deploy` SHALL be invoked, which runs `darwin-rebuild switch --flake ./nix ...`
- AND the deploy SHALL succeed without requiring any profile-selecting flag

### Requirement: init.sh accepts --all flag
`init.sh` SHALL accept an `--all` flag that runs the paths stage (sed + git hooks) and the bootstrap stage, in order. It SHALL NOT perform a full profile-specific deploy itself; instead it SHALL print instructions directing the user to run `init.sh --deploy` (or `just deploy`) next, which will auto-resolve the correct profile via hostname.

#### Scenario: --all flag bootstraps only, does not deploy
- WHEN the user runs `init.sh --all`
- THEN the paths stage (sed substitution, git hook activation) and the bootstrap stage SHALL run in order
- AND no full `darwin-rebuild switch` deploy SHALL be triggered as part of `--all` itself
- AND the script SHALL print guidance to run `init.sh --deploy` or `just deploy` next
