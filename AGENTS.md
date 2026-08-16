# AGENTS.md - Guidelines for AI Coding Agents

This document provides guidelines for AI coding agents operating in this repository. This is a Nix-based configuration management system for macOS (Darwin), built on `nix-darwin` and `home-manager`.

## Project Overview

- **Primary Language**: Nix (functional configuration language)
- **Secondary Languages**: Bash, Shell scripts
- **Configuration Framework**: `nix-darwin` (system configuration) + `home-manager` (user configuration)
- **Task Runner**: `just` (command runner with recipes in `Justfile`)
- **Package Manager**: Nix Flakes, Homebrew via `nix-homebrew` (macOS)
- **Theming**: `stylix` (system-wide color/styling theme)

## Build/Lint/Test Commands

### Dry Run Validation
```bash
# Check configuration without applying changes
just check
```

### Deploy Configuration
```bash
# Apply system configuration
just deploy

# Deploy with extended debug trace output
just verbose
```

**⚠️ IMPORTANT**: AI agents must **NEVER** call `just deploy` or `just verbose` as they require interactive sudo authentication and modify the running system. Only call `just check` for validation. The user must manually run `just deploy` when ready.

### Maintenance Commands
```bash
# Update flake lock file (remember to redeploy after)
just up

# Update flake lock file, commit changes, and redeploy
just update

# Update Homebrew flake inputs (remember to redeploy after)
just update-brew

# Pin nixpkgs-unstable to a specific commit
just up-unstable-to <hash>

# Optimise the Nix store
just optimise
```

### Cleanup Commands
```bash
# Keep only 5 generations, garbage collect, and redeploy
just sanitize-all

# Keep only 5 generations
just keep5

# Remove all generations older than 7 days
just clean

# Reclaim unused space (slow)
just gc

# Prune all other generations (destructive, requires confirmation)
just prune
```

**⚠️ IMPORTANT**: Cleanup and maintenance commands that call `sudo` or modify the system (`sanitize-all`, `keep5`, `clean`, `gc`, `prune`, `update`, `deploy`, `verbose`) must **NEVER** be run by AI agents without explicit user request, since they are destructive and/or require interactive sudo.

### Info/Debug Commands
```bash
# List all current available system generations
just list

# Show a searchable dependency tree
just tree

# Load the current flake in a Nix repl
just repl
```

### Validation Commands
```bash
# Check if git status is clean before deploying
git status

# Test flake integrity
nix flake check --no-build ./nix

# Check Nix code formatting without modifying files
nix fmt -- --fail-on-change

# Find dead/unused Nix code
deadnix --fail .

# Static analysis for Nix best practices
statix check .
```

### Post-Apply Validation (Mandatory for openspec changes)

After implementing ALL tasks in an openspec change, **always** run this validation
sequence before marking the change complete. Do NOT skip steps.

```bash
# Step 1: Stage all Nix files (required — Nix only evaluates git-tracked files)
git add nix/

# Step 2: Flake integrity
nix flake check --no-build ./nix

# Step 3: Formatting (use nix fmt, NOT treefmt — not running in CI)
nix fmt

# Step 4: Static analysis — dead code detection
deadnix --fail .

# Step 5: Static analysis — Nix best practices
statix check .
```

**If any step fails:**
1. Fix the issue
2. Re-run from Step 2 onward
3. Do NOT proceed until all steps pass

**Note:** `just check` (dry-run deploy) is a separate validation that tests the
full darwin-rebuild evaluation. It should ALSO be run, but it requires `sudo` and
is NOT part of the automated post-apply sequence. Run it manually when ready.

**⚠️ IMPORTANT**: AI agents must **NEVER** call `just deploy` or `just verbose`.
Only the validation steps above (which don't require sudo) should be run
automatically. `just check` requires sudo and should only be run on explicit request.

## Code Style Guidelines

### Nix Code Style

**Formatting & Indentation**:
- Use 2-space indentation (standard Nix convention)
- Keep lines reasonably short (80-100 characters)
- Use `nix fmt` (uses `nixfmt-tree` via the flake formatter) for automatic formatting

**File Organization and Structure**:
```nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
  # Add any custom inputs here
}:

let
  # Local functions and helper definitions
  myFunction = ...;
in
{
  # Configuration and module content
}
```

**Imports & Declarations**:
- Destructure inputs at the top of modules: `{ config, lib, pkgs, inputs, ... }`
- Group imports logically (system imports, home-manager, custom modules)
- Use relative paths for local imports: `../../modules/home/example.nix`

**Naming Conventions**:
- Module names: kebab-case or snake_case matching existing convention (e.g., `oh_my_posh.nix`, `neovim.nix`)
- Directory names: kebab-case (e.g., `nix/modules/home/`)
- Option names: camelCase (e.g., `enableSomething`, `myPackages`)
- Constants: camelCase or UPPER_CASE

**Package Management**:
- Pin packages to specific versions when required for stability
- Use `pkgs.unstable.*` for packages needing newer versions
- Reference packages from appropriate inputs: `pkgs`, `pkgs.unstable`
- Group related packages in logical sections with comments

**Configuration Structure**:
```nix
{
  imports = [ /* modules */ ];

  # Option overrides first
  options = { /* custom options */ };

  # Configuration comes next, grouped by concern
  programs.foo.enable = true;
  home.packages = with pkgs; [ ... ];

  # Services and system configuration
  services.bar.enable = true;
}
```

### Bash/Shell Script Style

**Format & Structure**:
- Use `#!/usr/bin/env bash` shebang
- Set options like `set -euo pipefail` for safety
- Indent with 2 spaces
- Quote all variable references: `"${variable}"`

**Naming**:
- Function names: snake_case
- Constants: UPPER_CASE
- Local variables: lowercase

**Error Handling**:
- Use error exit codes appropriately
- Check git status before dangerous operations
- Add user-friendly error messages
- Exit with clear status codes (0 = success, 1 = error)

### Comments & Documentation

**Nix Comments**:
- Use `#` for single-line comments
- Group related configuration with section comments
- Document non-obvious configuration choices
- Link to external references or TODOs when relevant

**Bash Comments**:
- Explain the "why" not just "what"
- Document complex logic
- Add headers for major sections

## Testing Tools

- `nix-tree`: Shows searchable dependency tree (run with `just tree`)

## Git Conventions

### Commit Messages

Follow Conventional Commit format:
```
<type>(<scope>): <description>
```

**IMPORTANT**:
- Commit messages MUST be a single line
- Do NOT include a body or additional lines
- **Exception**: Breaking changes may include a body explaining the breaking change and migration path

Breaking change format (rare):
```
<type>(<scope>)!: <description>

BREAKING CHANGE: Explanation of what breaks and how to migrate
```

**Types**:
- `feat`: New feature or configuration
- `fix`: Bug fix or configuration correction
- `chore`: Maintenance, dependency updates
- `refactor`: Code restructuring without changing behavior
- `docs`: Documentation updates
- `style`: Formatting, linting fixes

**Scopes** (examples):
- `home`: Changes to home-manager configuration
- `nix`: Core Nix configuration files
- `darwin`: macOS/nix-darwin-specific changes
- `shell`: Shell/bash scripts
- `openspec`: Spec-driven change proposals
- `deps`: Dependency updates

### Workflow

**IMPORTANT**: AI agents must ALWAYS ask for explicit permission before committing or pushing changes.

#### Making Changes
1. Make file changes as requested
2. Run `just check` to validate system changes
3. Run `nix fmt -- --fail-on-change` to validate formatting (or run `nix fmt` to fix)
4. Show git diff/status to demonstrate what changed

#### Committing Changes
5. **Draft a commit message** following the conventional commit format
6. **Show the commit message to the user** and ask for approval
7. **Wait for explicit confirmation** before running `git commit`
8. Only commit after receiving user approval

#### Pushing Changes
9. **NEVER push automatically** - always ask first
10. **Wait for explicit "yes" or "push it"** confirmation
11. Only run `git push` after receiving clear permission
12. Always ensure git status is clean before deploying

**Exception**: If the user explicitly asks you to "commit and push" in a single request, you may do both, but still show what you're committing first.

## File Locations & Organization

```
nix/
├── flake.nix                 # Main flake configuration (also defines rootPath inline)
├── features.nix              # Feature flags
├── darwin/                   # nix-darwin system configuration
│   ├── default.nix
│   ├── home.nix
│   └── profiles/             # personal / work profiles
├── modules/
│   └── home/                 # home-manager modules
├── options/                  # Nix option definitions
└── lib/                      # Nix helper functions (e.g. resolve-module.nix)

dotfiles/                     # Dotfiles deployed into the home directory
openspec/                     # Spec-driven change proposals (changes/, specs/)
Justfile                      # Task runner recipes
init.sh                       # Repo bootstrap/init script
```

## Key Tools & Technologies

- **home-manager**: User-level configuration management
- **stylix**: System-wide color/styling theme
- **nix-tree**: Dependency tree visualization
- **nixpkgs**: Official Nix packages repository
- **nix-darwin**: macOS configuration framework
- **nix-homebrew**: Homebrew integration for macOS

## Testing & Validation

Before making changes:
1. Run `just check` for dry-run validation
2. Verify changes don't break imports
3. Test configuration compiles with `nix flake check --no-build ./nix`
4. Run `nix fmt -- --fail-on-change` to validate formatting
5. Run `deadnix --fail .` to find dead/unused code
6. Run `statix check .` for static analysis
7. Ensure git status is clean

## Additional Resources

- Run `just` to see all available commands
- See `Justfile` for task definitions
- See `openspec/` for spec-driven change proposals and workflows

## Quick Reference: Validation Commands

- `just check`: Dry-run validation
- `nix fmt -- --fail-on-change`: Nix code formatting validation
- `nix flake check --no-build ./nix`: Flake integrity check
- `deadnix --fail .`: Dead/unused code detection
- `statix check .`: Static analysis for Nix best practices
- `just tree`: View dependency tree

<!-- headroom:rtk-instructions -->
# RTK (Rust Token Killer) - Token-Optimized Commands

When running shell commands, **always prefix with `rtk`**. This reduces context
usage by 60-90% with zero behavior change. If rtk has no filter for a command,
it passes through unchanged — so it is always safe to use.

## Key Commands
```bash
# Git (59-80% savings)
rtk git status          rtk git diff            rtk git log

# Files & Search (60-75% savings)
rtk ls <path>           rtk read <file>         rtk grep <pattern>
rtk find <pattern>      rtk diff <file>

# Test (90-99% savings) — shows failures only
rtk pytest tests/       rtk cargo test          rtk test <cmd>

# Build & Lint (80-90% savings) — shows errors only
rtk tsc                 rtk lint                rtk cargo build
rtk prettier --check    rtk mypy                rtk ruff check

# Analysis (70-90% savings)
rtk err <cmd>           rtk log <file>          rtk json <file>
rtk summary <cmd>       rtk deps                rtk env

# GitHub (26-87% savings)
rtk gh pr view <n>      rtk gh run list         rtk gh issue list

# Infrastructure (85% savings)
rtk docker ps           rtk kubectl get         rtk docker logs <c>

# Package managers (70-90% savings)
rtk pip list            rtk pnpm install        rtk npm run <script>
```

## Rules
- In command chains, prefix each segment: `rtk git add . && rtk git commit -m "msg"`
- For debugging, use raw command without rtk prefix
- `rtk proxy <cmd>` runs command without filtering but tracks usage
<!-- /headroom:rtk-instructions -->
