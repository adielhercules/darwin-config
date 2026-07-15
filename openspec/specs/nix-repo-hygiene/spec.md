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
