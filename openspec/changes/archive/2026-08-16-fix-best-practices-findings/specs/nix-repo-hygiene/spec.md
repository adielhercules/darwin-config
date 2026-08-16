## ADDED Requirements

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
