## Context

The darwin-config is a nix-darwin + home-manager setup targeting `aarch64-darwin`. It uses nixpkgs `24.11` as the stable channel, nixpkgs-unstable as an overlay, and Stylix for theming. The current `home.stateVersion = "24.11"` means home-manager applies legacy defaults for options whose defaults changed in later releases. Five warning classes surface on every `darwin-rebuild switch`, all of which have straightforward, low-risk fixes.

Files in scope:
- `nix/darwin/home.nix` — main home-manager config
- `nix/modules/home/neovim.nix` — neovim module with its own package list
- `nix/darwin/default.nix` — darwin system config with nixpkgs overlays

## Goals / Non-Goals

**Goals:**
- Eliminate all five warning classes from `darwin-rebuild switch` output
- Adopt new home-manager/nixpkgs defaults where appropriate for this macOS setup
- Keep each fix minimal and isolated (one option per warning)

**Non-Goals:**
- Bumping `home.stateVersion` beyond `25.05` (only the minimum bump needed to stay ahead of the oldest warning threshold)
- Refactoring unrelated config
- Upgrading the nixpkgs channel version

## Decisions

### 1. `nixfmt-classic` → `nixfmt`
Replace the package name in `home.packages` in both `home.nix` and `neovim.nix`. `nixfmt` (rfc-style) is the official successor and is a drop-in replacement for formatting purposes. No config file changes needed.

**Alternatives considered:** Keep `nixfmt-classic` via an overlay pin — rejected, the package is unmaintained and will eventually be removed.

### 2. `system` → `stdenv.hostPlatform.system` in overlays
`nix/darwin/default.nix` references `final.system` and `prev.system` inside a `nixpkgs.overlays` expression. These are the deprecated attribute paths. Replace with `final.stdenv.hostPlatform.system` and `prev.stdenv.hostPlatform.system` respectively.

The local `let system = "aarch64-darwin";` binding and its use at `nixpkgs.hostPlatform = system` are **not** affected — those are plain Nix values, not nixpkgs attribute references.

**Alternatives considered:** Use the string literal `"aarch64-darwin"` directly — viable but less portable; prefer the canonical attribute path.

### 3. `programs.git.signing.format = null`
No commit signing is configured in this repo. Setting `format = null` adopts the new default (no format assumed) and is semantically correct for an unsigned-commit workflow.

**Alternatives considered:** Set `"openpgp"` to preserve legacy behavior — unnecessary since signing is not in use.

### 4. `gtk.gtk4.theme = null`
This is a macOS-only setup with no GTK applications. The warning fires because home-manager evaluates the GTK module regardless. Setting `null` adopts the new default and is the correct choice — it does not attempt to apply a theme to non-existent GTK4 apps.

**Alternatives considered:** Set `config.gtk.theme` to mirror GTK3 — irrelevant on macOS where GTK is not used.

### 5. `home.stateVersion = "25.05"`
The two warnings with version thresholds are `programs.git.signing.format` (threshold `25.05`) and `gtk.gtk4.theme` (threshold `26.05`). Bumping to `25.05` clears the git warning via stateVersion and the GTK warning via explicit `null`. This is the minimum bump that keeps the config current without over-reaching.

**Review before applying:** Confirm no home-manager options between `24.11` and `25.05` have breaking defaults that affect this config (ghostty, neovim, helix, zellij, git modules).

**Alternatives considered:** Bump to `26.05` — premature; introduces more behavior changes than needed right now.

## Risks / Trade-offs

- **`home.stateVersion` bump** → Any home-manager option whose default changed between `24.11` and `25.05` will silently adopt its new default. Mitigation: audit the HM `25.05` release notes for modules in use (git, neovim, zellij) before applying; the explicit `programs.git.signing.format = null` and `gtk.gtk4.theme = null` already pre-empt the two known changes.
- **`nixfmt` output format differs from `nixfmt-classic`** → Existing `.nix` files formatted with `nixfmt-classic` will reformat differently. Mitigation: this is a formatter tool, not a build input; no functional impact. Run a bulk reformat pass separately if desired.
- **`stdenv.hostPlatform.system` in overlay** → If the overlay is evaluated before `stdenv` is available, this could error. Mitigation: the overlay pattern `final: prev:` always has `final.stdenv` available since `stdenv` is a base nixpkgs attribute; this is safe.

## Migration Plan

1. Apply all five fixes as a single commit (they are independent and non-interactive)
2. Run `darwin-rebuild switch` and verify zero warnings in the five categories
3. Confirm system boots and all tools (neovim, git, zellij) function correctly
4. **Rollback:** `git revert` the commit and re-run `darwin-rebuild switch` — all changes are reversible

## Open Questions

- None — all decisions are resolved based on the macOS-only context and user preferences confirmed above.
