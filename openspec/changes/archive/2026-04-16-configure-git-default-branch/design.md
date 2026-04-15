## Context

This change configures git's default branch name at the system level through home-manager's declarative configuration. Currently, `git init` defaults to `master`, but industry standard has shifted to `main`. Home-manager provides a clean way to apply this configuration globally through the `programs.git.extraConfig` option.

## Goals / Non-Goals

**Goals:**
- Set `init.defaultBranch = main` for all new git repositories
- Apply configuration through home-manager for declarative state management
- Ensure configuration is persistent across home-manager activations

**Non-Goals:**
- Rename existing branches in any repositories
- Modify git configuration for individual projects
- Change any other git settings beyond default branch name

## Decisions

**Decision 1: Use home-manager `programs.git.extraConfig` instead of manual `.gitconfig`**
- **Rationale**: Home-manager provides declarative configuration management, version control, and reproducibility. It's the standard approach in this Nix-Darwin setup.
- **Alternative 1**: Manual `~/.gitconfig` editing - would lack version control and reproducibility
- **Alternative 2**: Direct `git config --global` command - would be imperative and not persisted in config

**Decision 2: Set `init.defaultBranch` in extraConfig section**
- **Rationale**: The `init.defaultBranch` option is a straightforward git configuration that needs to be persisted globally. Home-manager's `extraConfig` section is designed for arbitrary git config key-value pairs.
- **Alternative 1**: Direct Nix `programs.git` options - git module doesn't have a dedicated option for this yet

## Risks / Trade-offs

[Risk] Configuration applies only to new repositories → Mitigation: Document that existing repos are unaffected; users can manually rename branches if desired
[Risk] Home-manager activation required for changes to take effect → Mitigation: This is standard; users already use home-manager for system management
[Trade-off] Using extraConfig adds raw git configuration to home-manager; future Nix options might make this obsolete → Acceptable: extraConfig is specifically designed for forward compatibility

## Migration Plan

1. Add git configuration to home-manager module via `programs.git.extraConfig`
2. Run home-manager activation to apply the change
3. Verify with `git config --global init.defaultBranch` (should show `main`)
4. New `git init` commands will use `main` as the default branch
5. No rollback needed - configuration is declarative and can be easily reverted

## Open Questions

None - configuration is straightforward and well-supported by git and home-manager.
