## Requirements

### Requirement: Flake formatter output
The flake SHALL expose a `formatter` output for each supported system so that `nix fmt` formats all Nix files in the repository using a consistent formatter.

#### Scenario: Running nix fmt
- **WHEN** a contributor runs `nix fmt` from the repo root
- **THEN** all `.nix` files are reformatted consistently with no errors, and the command exits successfully

### Requirement: Automated CI checks
The repository SHALL run automated checks on push and pull request via GitHub Actions, covering flake evaluation (`nix flake check`), formatting, and static analysis (`deadnix`, `statix`).

#### Scenario: CI passes on a clean change
- **WHEN** a commit is pushed or a pull request is opened against the repository
- **THEN** the CI workflow runs `nix flake check`, a formatting check, `deadnix`, and `statix`, and reports pass/fail status on the commit/PR

#### Scenario: CI fails on formatting drift
- **WHEN** a `.nix` file is committed that does not match the `formatter` output's formatting
- **THEN** the CI workflow's formatting check step fails, surfacing the drift to the contributor

### Requirement: Deduplicated flake inputs
Flake inputs that declare their own `nixpkgs` input SHALL follow the repository's primary `nixpkgs` input via `inputs.nixpkgs.follows = "nixpkgs"` wherever doing so does not break flake evaluation or the input's usable packages.

#### Scenario: devenv follows primary nixpkgs
- **WHEN** the flake is locked and evaluated
- **THEN** the `devenv` input's `nixpkgs` follows the top-level `nixpkgs` input, unless doing so breaks `nix flake check`, in which case the `follows` is omitted for that input only and the reason is documented in the change's task notes

#### Scenario: zjstatus follows primary nixpkgs
- **WHEN** the flake is locked and evaluated
- **THEN** the `zjstatus` input's `nixpkgs` follows the top-level `nixpkgs` input, unless doing so breaks `nix flake check`, in which case the `follows` is omitted for that input only and the reason is documented in the change's task notes

#### Scenario: nix-homebrew follows primary nixpkgs
- **WHEN** the flake is locked and evaluated
- **THEN** the `nix-homebrew` input's `nixpkgs` follows the top-level `nixpkgs` input, unless doing so breaks `nix flake check`, in which case the `follows` is omitted and the reason is documented

### Requirement: No dead or system-inapplicable flake outputs
The flake's `outputs` SHALL NOT contain entries for systems that the configuration does not target. For a macOS-only configuration, no `x86_64-linux` or other Linux-only entries SHALL be present in formatter or package outputs.

#### Scenario: No Linux formatter on macOS-only config
- **WHEN** the flake outputs are inspected
- **THEN** the `formatter` attribute set SHALL only contain entries for `aarch64-darwin` (or other macOS systems the config targets)
- **AND** no `x86_64-linux` or other non-Darwin entries SHALL be present

### Requirement: No duplicate packages across system and user profiles
A package SHALL NOT appear in both `environment.systemPackages` (system-level) and `home.packages` (user-level) unless there is a documented reason for the duplication.

#### Scenario: No duplicate devenv
- **WHEN** `nix/darwin/profiles/defaults.nix` already includes `devenv` in `environment.systemPackages`
- **THEN** `nix/darwin/home.nix` SHALL NOT also include `devenv` in `home.packages`

#### Scenario: No duplicate fd
- **WHEN** `nix/darwin/home.nix` defines `home.packages`
- **THEN** each package SHALL appear at most once in the list

### Requirement: No unused function arguments (deadnix clean)
All Nix module function arguments SHALL be used within the module body. Unused arguments SHALL be removed to satisfy `deadnix --fail .`.

#### Scenario: No unused pkgs in opencode.nix
- **WHEN** `nix/modules/home/opencode.nix` is inspected
- **THEN** the function args SHALL NOT include `pkgs` unless it is referenced in the module body

#### Scenario: No unused lib in helix.nix after mkForce removal
- **WHEN** `lib.mkForce` is removed from helix settings (task 3.1)
- **THEN** the `lib` argument SHALL be removed from helix.nix function args if no longer used

### Requirement: No repeated attribute set keys (statix clean)
An attribute set SHALL NOT assign the same key multiple times at the same level. Multiple assignments to the same key SHALL be merged into a single attribute set definition.

#### Scenario: Single xdg.configFile block in opencode.nix
- **WHEN** `nix/modules/home/opencode.nix` configures `xdg.configFile`
- **THEN** all `xdg.configFile` entries SHALL be defined in a single `xdg.configFile = { ... };` block, not as separate assignments

#### Scenario: No unnecessary parentheses in zjstatus.nix
- **WHEN** `nix/modules/home/zellij/zjstatus.nix` uses `lib.optional`
- **THEN** parentheses around the condition SHALL be omitted when they wrap a simple attribute path (e.g., `lib.optional condition value` not `lib.optional (condition) value`)

### Requirement: No orphaned or dead configuration artifacts
The repository SHALL NOT contain unimported/unused module files, Justfile recipes referencing nonexistent flake inputs, or comments referencing files/paths that do not exist in the tree.

#### Scenario: No unused duplicate modules
- **WHEN** the repository tree is inspected for `.nix` files under `nix/`
- **THEN** every `.nix` file is either imported by another module/flake output or is itself a flake entry point, with no orphaned duplicate files left unused

#### Scenario: No broken Justfile recipes
- **WHEN** any `just` recipe defined in the `Justfile` references a flake input by name
- **THEN** that input actually exists in `nix/flake.nix`, or the recipe has been removed/corrected

### Requirement: Idiomatic boolean option declarations
Custom boolean enable/disable options SHALL be declared using `lib.mkEnableOption` rather than a hand-rolled `lib.mkOption` of type `bool`, unless additional metadata beyond enable/disable is required for that specific option.

#### Scenario: Fish shell enable option
- **WHEN** the `lcars.shell.fish` option module is evaluated
- **THEN** its enable/disable toggle is declared via `lib.mkEnableOption`, and existing consumers (`darwin/home.nix`, `darwin/default.nix`) continue to read `lcars.shell.fish.enable` with unchanged default behavior

### Requirement: Clear error on invalid profile selection
Building a darwin configuration with an unrecognized profile name SHALL produce a clear, custom assertion error rather than an opaque file-not-found evaluation error.

#### Scenario: Building an unknown profile
- **WHEN** `mkDarwinConfig` (or equivalent profile-construction logic in `nix/darwin/default.nix`) is invoked with a profile name that is not `personal` or `work`
- **THEN** flake evaluation fails with a clear assertion message naming the invalid profile and the set of valid profiles, instead of a generic "path does not exist" error

#### Scenario: Building a known profile still works
- **WHEN** `mkDarwinConfig` is invoked with `personal` or `work`
- **THEN** the corresponding darwin configuration builds/evaluates successfully as before, with no behavior change

### Requirement: No stray or backup files committed
The repository SHALL NOT contain committed working files that are byproducts of manual editing
or testing (e.g. timestamped `*.backup-*` files, editor swap files). Such files, if found
tracked or staged, SHALL be removed rather than retained in git history going forward.

#### Scenario: Timestamped backup file removed
- **WHEN** a file matching a manual-backup naming pattern (e.g.
  `config.toml.backup-20260816-120353-530`) is found tracked or staged in the repository
- **THEN** the file SHALL be deleted and the deletion committed, rather than left in the tree

### Requirement: Unstable package usage documented inline
Every use of `pkgs.unstable.<package>` in a home-manager or nix-darwin module SHALL carry an
inline comment, adjacent to the usage, explaining why that package is sourced from the
`nixpkgs-unstable` overlay rather than the primary pinned `nixpkgs` (26.05) input.

#### Scenario: Comment present for each unstable usage
- **WHEN** a module file contains a reference to `pkgs.unstable.<package>`
- **THEN** a comment within the same file, positioned at or immediately above that usage,
  states the reason the unstable channel is required (e.g. a fix or feature not yet available
  in the pinned stable release)

### Requirement: Pre-commit hook enforces or does not exist
`.githooks/pre-commit` (or any equivalent local git hook shipped by this repository) SHALL
either run a meaningful subset of the same checks enforced by CI (at minimum, Nix formatting and
`statix` static analysis), or SHALL NOT be present/wired up at all. A hook that always exits
successfully without performing any check SHALL NOT be committed.

#### Scenario: Hook runs real checks
- **WHEN** `.githooks/pre-commit` is invoked (directly or via a `git commit`)
- **THEN** it runs at least a Nix formatting check (e.g. `nixfmt-tree --ci`) and `statix check .`
  against the `nix/` directory, and exits non-zero if either check fails

### Requirement: In-repo path references stay accurate after moves/renames
Comments anywhere in the repository (Nix modules, shell scripts, top-level docs) that reference
another file or directory by its repo-relative path SHALL be updated whenever that referenced
path is renamed, moved, or removed. This applies both to prose documentation (e.g. AGENTS.md's
file-locations section) and to inline code comments.

#### Scenario: AGENTS.md reflects current structure
- **WHEN** `AGENTS.md`'s "File Locations & Organization" section is inspected
- **THEN** every path listed SHALL correspond to a directory or file that currently exists

#### Scenario: In-code comment references stay current
- **WHEN** a Nix module or shell script comment references another in-repo file by path
- **THEN** that referenced path SHALL correspond to a file/directory that currently exists,
  updated to match the new location if the target was renamed or moved
