## MODIFIED Requirements

### Requirement: Profile-based deployment via hostname-keyed flake outputs
The system SHALL allow users to select a deployment profile (personal or work) automatically, based on the machine's hostname, via hostname-keyed `darwinConfigurations` flake outputs — `darwinConfigurations."Adiels-MacBook-Pro"` (personal) and `darwinConfigurations."MPCE-MBP-RWF4347WJP"` (work). Running `darwin-rebuild switch --flake .` (no `#attr` suffix) SHALL auto-resolve to the attribute matching the machine's current hostname via nix-darwin's built-in hostname-based resolution. Explicit `--flake ".#<hostname>"` targeting SHALL remain available as a manual override/escape hatch. The internal `profile` string (`"personal"`/`"work"`) used throughout module resolution (`mkModules`, `mkSpecialArgs`, `resolveModule`) SHALL be derived from a hostname → profile mapping and SHALL remain unchanged in value and behavior from prior versions of this spec.

#### Scenario: Auto-deploy on personal machine
- WHEN the user runs `darwin-rebuild switch --flake . --impure` on a machine whose hostname is `Adiels-MacBook-Pro`
- THEN nix-darwin resolves `darwinConfigurations."Adiels-MacBook-Pro"` automatically
- AND the configuration includes only personal-only brew casks, system packages, and module configurations (no work-specific entries)

#### Scenario: Auto-deploy on work machine
- WHEN the user runs `darwin-rebuild switch --flake . --impure` on a machine whose hostname is `MPCE-MBP-RWF4347WJP`
- THEN nix-darwin resolves `darwinConfigurations."MPCE-MBP-RWF4347WJP"` automatically
- AND the configuration includes only work-only brew casks, system packages, and module configurations (no personal-specific entries)

#### Scenario: Explicit hostname-keyed target still works as an override
- WHEN the user runs `darwin-rebuild switch --flake ".#MPCE-MBP-RWF4347WJP" --impure` regardless of the machine's actual current hostname
- THEN the configuration matching the `work` profile is built and deployed, exactly as if hostname auto-resolution had selected it

#### Scenario: Unrecognized hostname fails to resolve
- WHEN the user runs `darwin-rebuild switch --flake . --impure` on a machine whose hostname matches neither `Adiels-MacBook-Pro` nor `MPCE-MBP-RWF4347WJP`
- THEN the build fails because no matching `darwinConfigurations` attribute exists for that hostname
- AND the user must either update the hostname → profile mapping or use an explicit `--flake ".#<hostname>"` target

#### Scenario: Shared pkgs accessible independent of profile name
- WHEN a consumer of this flake accesses `self.darwinConfigurations.pkgs`
- THEN the resolved package set (with `unstable`/`zjstatus` overlays applied) is returned, sourced from either profile's build since overlays are identical across `personal` and `work`
- AND no separate `darwinPackages` output exists (removed; the `pkgs` attribute lives directly inside `darwinConfigurations` as a sibling of the hostname-keyed entries)
