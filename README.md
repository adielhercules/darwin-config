# darwin-config

Adiel's Nix-Darwin system flake — a fully declarative macOS system
configuration built on [`nix-darwin`](https://github.com/nix-darwin/nix-darwin)
and [`home-manager`](https://github.com/nix-community/home-manager), with
Homebrew managed through Nix ([`nix-homebrew`](https://github.com/zhaofengli-wip/nix-homebrew))
and system-wide theming via [`stylix`](https://github.com/nix-community/stylix).

## What this is

This repository declaratively configures an entire macOS machine: system
defaults (Dock, Finder, keyboard, etc.), Homebrew casks/brews/Mac App Store
apps, shell and editor tooling, dotfiles, and per-machine differences via a
**personal**/**work** profile split that's automatically selected based on
the machine's hostname (see `hostProfiles` in `nix/darwin/default.nix`).
Currently targets Apple Silicon (`aarch64-darwin`) only.

## Prerequisites

- **[Lix](https://lix.systems/)** — this config uses Lix instead of upstream
  Nix. Follow the [Lix install instructions](https://lix.systems/install/)
  for macOS. Lix is required specifically because this repo relies on
  Lix-specific behavior (e.g. `nix.enable = false` in
  `nix/darwin/default.nix`, since Lix manages its own daemon rather than
  nix-darwin managing one for it) and Lix's stricter defaults (explicit
  `--extra-experimental-features` flags are used throughout for
  `nix-command`/`flakes`, which Lix doesn't enable by default).
- **git** — to clone this repository.
- An Apple Silicon Mac.
- You do **not** need to install [`just`](https://github.com/casey/just)
  manually — it's declared as a system package by this same flake and
  becomes available automatically after the first successful bootstrap.

## Installation (first-time bootstrap)

1. Install Lix (see Prerequisites above).
2. Clone this repository:
   ```
   git clone <this-repo-url> darwin-config
   cd darwin-config
   ```
3. Set your git identity's email (used for both the personal and work
   profiles; required before any deploy will succeed):
   ```
   ./init.sh --email you@example.com
   ```
4. **Work laptops only** — if this machine is on a corporate network with
   TLS interception, drop your corporate certificate(s) (`.crt`/`.pem`) into
   `~/.config/darwin-secrets/` *before* bootstrapping. `init.sh` auto-detects
   them and trusts them for the initial fetch only; see
   `nix/darwin/profiles/work.nix.example` for the full secrets-directory
   convention (proxy settings, substituters, etc.).
5. Run the bootstrap:
   ```
   ./init.sh
   ```
   (equivalent to `./init.sh --all`). This sets `rootPath` in
   `nix/flake.nix`, activates the repo's git hooks, and runs the initial
   `nix run nix-darwin/master#darwin-rebuild -- switch`. This step does
   **not** perform a full profile deploy yet.
6. Finish the deploy:
   ```
   ./init.sh --deploy
   ```
   (or `just deploy`, once `just` is available). The profile (`personal` or
   `work`) is selected automatically based on this machine's hostname.

## Day-to-day usage

Once bootstrapped, use `just` for all regular operations:

| Command | Purpose |
|---|---|
| `just check` | Dry-run validation — catches errors without generating a new generation |
| `just deploy` | Standard deploy (also runs store optimisation afterward) |
| `just verbose` | Deploy with extended debug trace output |
| `just up` | Update the flake lock file |
| `just update` | Update lock file, commit, and redeploy |
| `just update-brew` | Update Homebrew-related flake inputs |
| `just list` | List all current system generations |
| `just tree` | Show a searchable dependency tree |
| `just repl` | Load the current flake in a Nix repl |

Run `just` with no arguments to see the full list.

⚠️ **Destructive / system-modifying commands** (`sanitize-all`, `keep5`,
`clean`, `gc`, `prune`) require interactive `sudo` and/or are destructive —
run these deliberately, never as part of an automated flow.

## Profiles

Two profiles exist: `personal` and `work`, defined in
`nix/darwin/profiles/personal.nix` / `work.nix`, both layered on top of
shared config in `nix/darwin/profiles/defaults.nix`. The active profile is
selected automatically from the current machine's hostname via
`hostProfiles` in `nix/darwin/default.nix` — no manual profile flag is
needed for `just deploy`/`just check`.

The `work` profile additionally supports an external, git-ignored secrets
directory at `~/.config/darwin-secrets/` for corporate certificates, proxy
settings, and other machine-specific values that must never be committed.
See `nix/darwin/profiles/work.nix.example` for the expected shape and
auto-discovery conventions (certs are picked up automatically by filename
extension, no Nix changes required).

## Repository structure

```
├── init.sh                  # First-time bootstrap only (see above)
├── Justfile                 # Day-to-day commands (deploy, check, cleanup, ...)
├── nix/
│   ├── flake.nix             # Flake inputs/outputs
│   ├── features.nix          # Feature flags
│   ├── darwin/
│   │   ├── default.nix       # Main darwin-rebuild config, profile wiring
│   │   ├── home.nix          # home-manager entry point
│   │   └── profiles/         # personal.nix / work.nix / defaults.nix
│   ├── modules/home/         # Per-tool home-manager modules (git, fish,
│   │                           helix, neovim, ghostty, zellij, tuna, ...)
│   ├── options/               # Custom Nix option declarations
│   └── lib/                   # Shared helper functions (module resolution,
│                                git email, etc.)
├── dotfiles/                 # Dotfiles deployed into the home directory
└── openspec/                 # Spec-driven change proposals (changes/, specs/)
```

## Contributing

See `AGENTS.md` for commit conventions, code style, and validation
requirements, and `openspec/` for the spec-driven change proposal workflow
used for non-trivial changes to this repo.
