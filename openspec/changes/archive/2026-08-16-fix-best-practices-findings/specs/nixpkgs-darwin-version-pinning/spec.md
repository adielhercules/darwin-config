## ADDED Requirements

### Requirement: Stylix input pinning posture is deliberate and documented
The `stylix` flake input SHALL either be pinned to a specific release branch/tag consistent with
the matched stable trio (`nixpkgs`, `nix-darwin`, `home-manager`), or, if no such aligned
branch/tag exists upstream, `nix/flake.nix` SHALL carry an explicit comment adjacent to
`stylix.url` stating that the input intentionally tracks its default branch and that updates to
it should be performed deliberately (e.g. via a scoped `nix flake lock --update-input stylix`)
rather than incidentally via a broad `nix flake update`/`just up`.

#### Scenario: Stylix pinned to an aligned branch
- **WHEN** an upstream `nix-community/stylix` branch or tag aligned with the pinned 26.05 trio
  exists
- **THEN** `stylix.url` in `nix/flake.nix` SHALL reference that branch/tag rather than the bare
  repository default

#### Scenario: Stylix intentionally floating, documented
- **WHEN** no upstream branch/tag aligned with 26.05 exists for `stylix`
- **THEN** `nix/flake.nix` SHALL contain a comment immediately adjacent to `stylix.url` stating
  that the input intentionally floats on its default branch and describing how a deliberate
  update should be performed
