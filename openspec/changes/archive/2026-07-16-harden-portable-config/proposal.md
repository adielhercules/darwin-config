## Why

The repo currently hardcodes the maintainer's username (`adielhercules`) and home
directory path in several places (`nix/darwin/default.nix`, `work.nix`,
`ghostty.nix`, tuna config TOMLs), making the config non-portable to any other
machine/user without manual find-and-replace. Separately, the `work` profile's
corporate-certificate auto-discovery only takes effect *after* nix-darwin has
successfully activated once, so a brand-new work laptop on a network with TLS
interception cannot even complete its first bootstrap (`nix run ... -- switch`
fails fetching flake inputs before any cert config exists). Git identity is
also hardcoded per-profile (a real personal email committed to the repo, and
work placeholders that silently ship until manually edited), and there is no
top-level `README.md` documenting prerequisites (Lix) or the bootstrap flow at
all. This change fixes all four gaps together since they're all part of
preparing this config to be safely portable/re-bootstrappable on a new machine.

## What Changes

- Replace the hardcoded `username = "adielhercules";` in
  `nix/darwin/default.nix` with dynamic detection via `SUDO_USER`/`USER`
  environment variables, aborting with a clear error if neither is set.
- Remove all remaining hardcoded `/Users/adielhercules/...` path references:
  `work.nix`'s `secretsDir`, `ghostty.nix`'s per-user fish path, and the
  URL-encoded home path baked into the Tuna `config.toml` files (switched
  from a static file `source` to a generated `text` with a runtime path
  substitution).
- Fix the work-profile cert bootstrap chicken-and-egg problem: `init.sh`'s
  bootstrap stage now auto-detects `.crt`/`.pem` files already dropped into
  `~/.config/darwin-secrets/`, merges them into a temporary CA bundle, and
  exports `NIX_SSL_CERT_FILE`/`SSL_CERT_FILE`/`CURL_CA_BUNDLE` scoped only to
  that one bootstrap command (cleaned up afterward) — no manual system
  `ca-certificates.crt` symlink surgery or double-bootstrap required.
- Replace hardcoded/placeholder git identity with a single declarative,
  file-backed mechanism: git `user.name` is hardcoded to `"Adiel Hercules"`
  for both profiles; `user.email` is read at eval time from a new
  gitignored `.local/git-email` file via a shared `nix/lib/git-email.nix`
  helper, which hard-aborts with a clear message if the file is missing.
  `init.sh` gains a flexible `--email <address>` flag (usable standalone or
  combined with other stage flags) that writes/updates this file, plus a
  `require_email` guard before the bootstrap/deploy stages for early,
  friendly feedback.
- Add a new root `README.md` documenting what the project is, the Lix
  prerequisite (and why Lix specifically), first-time bootstrap steps
  (including `--email` and the `darwin-secrets` cert convention), day-to-day
  `just` commands, the personal/work profile system, repo structure, and a
  pointer to `AGENTS.md`/`openspec/` for contribution conventions.
- **BREAKING**: Any existing clone with a real, personal git email hardcoded
  in `git-personal.nix` will need to run `./init.sh --email <address>`
  before its next deploy, or the build will fail with a clear abort message.

## Capabilities

### New Capabilities
- `dynamic-user-detection`: Resolving the system username/home directory
  dynamically at eval time instead of a hardcoded literal, used everywhere
  a per-user path is needed (system config, work-profile secrets dir,
  per-user binary paths, templated dotfile configs).
- `git-email-config`: File-backed, declarative git `user.email` sourced from
  a local, gitignored file, with a hard build-time failure if unset, plus
  `init.sh` tooling to set it.
- `work-profile-cert-bootstrap`: Auto-detection and temporary export of
  work-profile corporate CA certs during the very first (pre-activation)
  `init.sh` bootstrap run, so the initial flake/store fetch succeeds on
  networks with TLS interception without manual system file edits.
- `project-readme`: A root `README.md` documenting prerequisites, install/
  bootstrap flow, day-to-day usage, and repo structure.

### Modified Capabilities
- `init-script`: Bootstrap stage gains cert auto-detection/export behavior;
  `work.nix.example`'s stale `deploy_work` reference is corrected to match
  the actual current stage names.
- `init-script-flags`: Adds the new `--email <address>` flag; existing flag
  behavior descriptions are reconciled with the actual current
  implementation (hostname-based profile auto-selection, not explicit
  `--personal`/`--work` flags, which the existing spec text had drifted
  away from).

## Impact

- **Affected files**: `nix/darwin/default.nix`, `nix/darwin/profiles/work.nix`,
  `nix/darwin/profiles/work.nix.example`, `nix/modules/home/ghostty.nix`,
  `nix/modules/home/tuna/default.nix`,
  `nix/modules/home/tuna/{personal,work}/config.toml`,
  `nix/modules/home/git-personal.nix`, `nix/modules/home/git-work.nix`,
  new `nix/lib/git-email.nix`, `init.sh`, new root `.gitignore`, new root
  `README.md`.
- **New local state**: `.local/git-email` (gitignored, not committed).
- **Dependencies**: none added; relies on existing `builtins.readFile`/
  `builtins.pathExists`/`--impure` conventions already used elsewhere in the
  repo (e.g. `work.nix`'s cert auto-discovery).
- **Systems**: affects both `personal` and `work` deploy profiles; the cert
  bootstrap fix is work-profile-specific only.
