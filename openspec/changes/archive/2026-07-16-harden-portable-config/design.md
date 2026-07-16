## Context

`nix/darwin/default.nix` hardcodes `username = "adielhercules";` as the single
source of truth, propagated via `specialArgs`/`home-manager.extraSpecialArgs`
to every profile/module. Several downstream files independently re-hardcode
the same literal path instead of deriving it (`work.nix`'s `secretsDir`,
`ghostty.nix`'s fish binary path, the Tuna `config.toml`'s URL-encoded
`Applications` path). Profile selection is hostname-based
(`hostProfiles` map in `nix/darwin/default.nix`), and `just` (used for all
day-2 deploys) is itself installed *by* this flake — meaning it is not
available before the very first successful activation, which is why
`init.sh`'s bootstrap stage calls `nix run nix-darwin/master#darwin-rebuild --
switch` directly rather than `just deploy`.

The `work` profile already has a reasonably good corporate-cert
auto-discovery mechanism (`builtins.readDir` over `~/.config/darwin-secrets/`
feeding `security.pki.certificateFiles`), but this is a nix-darwin option
that only takes effect *after* activation succeeds — it cannot help the very
first bootstrap run on a network with full TLS interception, since Nix's own
flake/store fetches happen before any Darwin module has been applied.

Git identity is currently split: `git-personal.nix` hardcodes a real email
address directly in source control; `git-work.nix` uses placeholder
strings (`<work-email-required>`) with a soft `warnings` mechanism that does
not block a deploy, just prints a warning.

There is no root `README.md` — install/bootstrap knowledge currently lives
only in `init.sh`'s inline comments/usage text and scattered `openspec`
change history.

## Goals / Non-Goals

**Goals:**
- Single dynamic source of truth for username/home directory, with no
  literal path duplicated anywhere else in the repo.
- A safe, scriptable fix for the work-profile cert bootstrap ordering
  problem that doesn't touch system-managed files or require running
  bootstrap twice.
- A single declarative source of truth for git email that hard-fails the
  build (not just a warning) if unset, while keeping `name` static and
  identical across both profiles.
- A root `README.md` covering prerequisites (Lix), install/bootstrap order,
  day-to-day commands, and profile behavior.

**Non-Goals:**
- Not migrating the profile-selection mechanism itself (hostname-based
  `hostProfiles` stays as-is).
- Not building general-purpose secrets management (e.g. agenix/sops) — the
  existing plain-file `~/.config/darwin-secrets/` convention is kept.
- Not solving TLS interception for *non-Nix* tooling invoked outside the
  bootstrap window (e.g. Homebrew's own network calls post-activation);
  those are already covered once `security.pki.certificateFiles` takes over
  after first activation.
- Not adding CI/lint enforcement for the new `README.md`'s accuracy.

## Decisions

**1. Username: `SUDO_USER`/`USER` env detection with hard abort, not a
default fallback.**
Chosen over silently defaulting to some placeholder because a wrong/empty
username would silently corrupt `users.users.${username}`, home-manager's
target user, and every derived path. Modeled on a pattern already proven in
a comparable dotfiles repo (corintho/dotfiles) that resolves the *invoking*
user correctly whether run directly or via `sudo darwin-rebuild`. Requires
Nix eval with `--impure`, which every `just` recipe (`check`/`deploy`/
`verbose`) already passes — no new constraint introduced.

**2. `work.nix`'s `secretsDir` derived from the same dynamic `username`/home,
not from `config.home.homeDirectory`.**
`work.nix` is a nix-darwin (system) module, not a home-manager module, so
`config.home.homeDirectory` isn't in scope there; it already has access to
`username` via `specialArgs`. Path is built as `"/Users/${username}"` (the
existing convention nix-darwin itself uses for `users.users.${username}.home`),
avoiding a second, differently-derived path for the same directory.

**3. Tuna `config.toml`: template substitution over `source =`, not full
Nix-native regeneration of the TOML.**
The Tuna app configs are large, hand-authored per-profile TOML files with
deep nested `[[comboMode.bindings]]` arrays (per existing comments in
`tuna/default.nix`); rewriting them as Nix-generated TOML would be a much
larger, riskier refactor for one hardcoded path. A targeted
`builtins.replaceStrings` swap of the URL-encoded home-path segment, applied
to the file's `text` at eval time, fixes the actual portability bug with
minimal surface area.

**4. Cert bootstrap: scoped env-var override (`NIX_SSL_CERT_FILE` et al.),
not the "manual symlink swap + deploy twice" pattern.**
Considered mirroring corintho/dotfiles' documented manual workaround
(temporarily symlink `/etc/ssl/certs/ca-certificates.crt` to the corporate
cert, let bootstrap fail once by design, revert, redeploy) — rejected
because it mutates a system-wide, nix-darwin-managed file outside of Nix's
control (affecting *all* TLS on the machine, not just Nix's fetches),
requires two full bootstrap attempts, and isn't automatable cleanly. Instead,
`init.sh`'s bootstrap stage checks `~/.config/darwin-secrets/` for existing
`.crt`/`.pem` files (the same directory/convention `work.nix` already reads
post-activation), concatenates any found into one temporary bundle file, and
exports `NIX_SSL_CERT_FILE`/`SSL_CERT_FILE`/`CURL_CA_BUNDLE` scoped only to
that one `nix run ... -- switch` child process — leaving no residual system
state to revert, and requiring only one bootstrap invocation. This assumes a
network with full TLS interception (all HTTPS re-signed by one corporate
root), matching the target scenario; the merged bundle approach still
generalizes correctly if multiple cert files exist. If no certs are found on
a work-profile machine, a warning is printed before attempting bootstrap
(mirroring `work.nix`'s existing soft-warning style) rather than hard-failing,
since the bootstrap may still succeed on non-intercepted networks.

**5. Git email: declarative Nix read (`builtins.readFile` + hard `abort`),
not an imperative `home.activation` script.**
An activation script running `git config --global user.email` would create
two competing sources of truth (home-manager's declarative `~/.gitconfig`
management vs. an imperative post-hoc mutation) and wouldn't fail the build
itself if the email were missing — it would silently skip and leave a stale
or absent email. Reading the file directly in `git-personal.nix`/
`git-work.nix` via a shared `nix/lib/git-email.nix` helper keeps git config
fully declarative and gives a hard, unbypassable failure at eval time
(`builtins.abort`) if `.local/git-email` is missing — this is the only
enforcement point that can't be skipped by going around `init.sh` (since
day-2 deploys use `just deploy` directly, never `init.sh`). `init.sh`'s
`require_email` check is an additional friendly early failure for first-time
bootstrap UX, not the sole guarantee.

**6. Git email file location: `.local/git-email`, not `.git-email` or
`~/.config/git/local`.**
A `.local/` subdirectory (vs. a single dotfile at repo root) leaves room to
add other local-only, non-secret machine state later without renaming
anything or growing root-level dotfile clutter. `.local/` is who owns this
convention going forward (gitignored wholesale) rather than the home
directory, since the value must be readable by `builtins.readFile` at Nix
eval time via `rootPath`, and keeping it inside the repo (vs.
`~/.config/...`) means it works identically regardless of `$HOME` layout.

**7. `README.md` written now, referencing not-yet-implemented behavior in the
same change.**
Since `--email` and the cert-bootstrap auto-detection ship in this same
change (not a follow-up), the README describes the end-state behavior
directly rather than being written twice.

## Risks / Trade-offs

- **[Risk] `builtins.getEnv "SUDO_USER"`/`"USER"` could resolve unexpectedly
  in unusual invocation contexts (e.g. some CI runner, or a shell that
  unsets `USER`).** → Mitigation: hard `abort` with a clear, actionable error
  message rather than silently falling back to a wrong value; this repo has
  no CI that evaluates the flake today, and all documented deploy paths
  (`just`, `init.sh`) run in a normal interactive shell where at least one of
  these is always set.
- **[Risk] Merging multiple `.crt`/`.pem` files into one temp bundle for
  `NIX_SSL_CERT_FILE` assumes they're all valid PEM-format CA certs; a
  malformed file could break the bootstrap fetch entirely.** → Mitigation:
  this mirrors the exact same file-discovery convention `work.nix` already
  uses post-activation (no new format assumption introduced), and the temp
  bundle is scoped/discarded per-run so a bad file only affects that one
  bootstrap attempt, not persistent system state.
  Users can fix and re-run without any cleanup dance.
- **[Risk] Existing clones will hit a hard build failure (`builtins.abort`)
  on their next deploy once `git-email.nix` lands, since `.local/git-email`
  won't exist yet.** → Mitigation: this is called out explicitly as
  **BREAKING** in the proposal; the abort message itself instructs exactly
  what command to run (`./init.sh --email you@example.com`) to unblock.
- **[Risk] Templating the Tuna TOML via `builtins.replaceStrings` is
  string-substitution, not a structural TOML edit — if the encoded path
  format ever changes (e.g. Tuna changes its URL-encoding scheme), the
  substitution could silently stop matching.** → Mitigation: low risk given
  this only needs to match a literal, currently-stable URL-encoded segment;
  worst case is the path reverts to the old hardcoded value, which is a
  no-worse-than-today regression, not a build failure.

## Migration Plan

1. Land the dynamic-username and de-hardcoded-path changes first (no
   external state required, no `.gitignore`d files needed yet).
2. Land the git-email mechanism together with `init.sh --email`; run
   `./init.sh --email <address>` locally before the next deploy on this
   machine to avoid the hard-abort.
3. Land the cert-bootstrap `init.sh` change; no action needed unless
   re-bootstrapping a work machine from scratch.
4. Add the root `README.md` last, once all referenced behavior exists, so it
   accurately documents the shipped state rather than aspirational behavior.
5. **Rollback**: each piece is independently revertible via `git revert`;
   there is no schema/data migration, only file/module changes and one new
   gitignored local file (`.local/git-email`), which can simply be deleted
   if reverting the git-email mechanism.

## Open Questions

- None outstanding — all four workstreams were discussed and confirmed with
  the maintainer before this proposal was written.
