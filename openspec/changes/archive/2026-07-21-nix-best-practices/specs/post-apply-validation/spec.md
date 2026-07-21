## ADDED Requirements

### Requirement: Mandatory post-apply validation sequence
After implementing all tasks in an openspec change, the agent SHALL run the following validation steps in order before marking the change complete. All steps MUST pass before the change is considered done.

#### Scenario: All validation steps pass
- **WHEN** all tasks in an openspec change have been implemented
- **THEN** the agent SHALL run:
  1. `git add nix/` (stage files — Nix only evaluates git-tracked files)
  2. `nix flake check --no-build ./nix` (flake integrity)
  3. `nix fmt` (formatting — using nix fmt, not treefmt since not in CI)
  4. `deadnix --fail .` (dead code detection)
  5. `statix check .` (static analysis)
- **AND** all steps SHALL exit successfully

#### Scenario: Validation step fails
- **WHEN** any validation step exits non-zero
- **THEN** the agent SHALL fix the issue and re-run from step 2 onward
- **AND** the agent SHALL NOT proceed until all steps pass

### Requirement: No deploy commands from AI agents
AI agents SHALL NOT run `just deploy` or `just verbose` as they require interactive sudo authentication and modify the running system. Only non-sudo validation steps are permitted.

#### Scenario: Agent runs validation only
- **WHEN** an AI agent is applying an openspec change
- **THEN** the agent SHALL only run the non-sudo validation steps (git add, nix flake check, nix fmt, deadnix, statix)
- **AND** the agent SHALL NOT run `just deploy`, `just verbose`, or any command requiring sudo

### Requirement: Validation commands documented in AGENTS.md
The `AGENTS.md` file SHALL document the full post-apply validation sequence under a dedicated section, including the rationale for each step and the difference between `just check` (darwin-rebuild check, requires sudo) and the automated validation suite.

#### Scenario: AGENTS.md contains validation section
- **WHEN** a contributor reads `AGENTS.md`
- **THEN** they SHALL find a "Post-Apply Validation" section listing all 5 validation steps with explanations

### Requirement: Validation rules in openspec config
The `openspec/config.yaml` file SHALL include `post-apply` rules requiring the validation sequence after every change implementation.

#### Scenario: openspec config has post-apply rules
- **WHEN** an agent reads `openspec/config.yaml` before implementing a change
- **THEN** it SHALL find `post-apply` rules specifying the mandatory validation steps
