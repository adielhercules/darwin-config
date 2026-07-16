## 1. Dynamic username/path de-hardcoding

- [x] 1.1 Replace `username = "adielhercules";` in `nix/darwin/default.nix`
  with `SUDO_USER`/`USER` env-based resolution + `builtins.abort` fallback
- [x] 1.2 Update `nix/darwin/profiles/work.nix` to accept `username` (already
  available via `specialArgs`) and derive `secretsDir` as
  `"/Users/${username}/.config/darwin-secrets"` instead of the hardcoded path
- [x] 1.3 Add `config` to `nix/modules/home/ghostty.nix`'s module args (if
  missing) and change the hardcoded fish path to use
  `"/etc/profiles/per-user/${config.home.username}/bin/fish"`
- [x] 1.4 Update `nix/darwin/profiles/work.nix.example`'s commented example
  path to a generic placeholder instead of the hardcoded literal
- [x] 1.5 Update `nix/modules/home/tuna/default.nix` to generate the deployed
  `config.toml` via `home.file."...".text` using `builtins.replaceStrings` to
  substitute the URL-encoded home path with the current user's, instead of
  `source = activeConfig;`
- [x] 1.6 Verify `nix/modules/home/tuna/{personal,work}/config.toml`'s
  hardcoded URL-encoded segment matches exactly what the substitution in 1.5
  targets

## 2. Cert bootstrap fix

- [x] 2.1 In `init.sh`, add logic before the bootstrap `nix run` invocation
  to check `~/.config/darwin-secrets/` for `.crt`/`.pem` files
- [x] 2.2 If cert files are found, concatenate them into a `mktemp`-created
  temporary bundle file
- [x] 2.3 Export `NIX_SSL_CERT_FILE`, `SSL_CERT_FILE`, and `CURL_CA_BUNDLE`
  pointing at the temp bundle, scoped to the bootstrap command's environment
  only (not persisted to the invoking shell)
- [x] 2.4 If no cert files are found, print a warning before attempting
  bootstrap (non-blocking)
- [x] 2.5 Ensure the temporary bundle file is deleted after the bootstrap
  command completes, whether it succeeds or fails (e.g. via `trap`)
- [x] 2.6 Update `work.nix.example`'s stale reference to a non-existent
  `deploy_work` function so it matches current `init.sh` stage names

## 3. Git email mechanism

- [x] 3.1 Create root `.gitignore` (none currently exists) with a `.local/`
  entry
- [x] 3.2 Create `nix/lib/git-email.nix`: reads `${rootPath}/.local/git-email`
  via `builtins.readFile`, trims whitespace, `builtins.abort`s with a clear
  instructional message if the file doesn't exist
- [x] 3.3 Update `nix/modules/home/git-personal.nix`: hardcode
  `name = "Adiel Hercules"`, source `email` from the new helper (passing
  `rootPath`/`lib` through module args)
- [x] 3.4 Update `nix/modules/home/git-work.nix`: same as 3.3, removing the
  old placeholder-string + `warnings` mechanism entirely
- [x] 3.5 Add `--email <address>` argument parsing to `init.sh`, scanning all
  args (not just `$1`) so it works standalone or combined with other flags;
  write the trimmed value to `.local/git-email` (creating the directory if
  needed) with `chmod 600`
- [x] 3.6 Add a `require_email` guard function in `init.sh`, called at the
  top of the bootstrap and deploy stages, exiting non-zero with guidance if
  `.local/git-email` is missing/empty
- [x] 3.7 Update `init.sh`'s usage/help text to document `--email`

## 4. Root README.md

- [x] 4.1 Write root `README.md`: title/description, what-this-is overview
- [x] 4.2 Prerequisites section: Lix (with link + brief why-Lix note), git,
  Apple Silicon Mac; explicit note that `just` is not a manual prerequisite
- [x] 4.3 Installation/bootstrap section: install Lix → clone repo → set git
  email (`./init.sh --email ...`) → (work only) drop certs into
  `~/.config/darwin-secrets/` → `./init.sh` (`--all`) → `./init.sh --deploy`
- [x] 4.4 Day-to-day usage section: table of key `just` commands, warning
  about destructive/system-modifying ones
- [x] 4.5 Profiles section: personal/work, hostname-based auto-selection,
  `~/.config/darwin-secrets/` convention
- [x] 4.6 Repository structure section: brief annotated tree
- [x] 4.7 Contributing section: pointer to `AGENTS.md` and `openspec/`

## 5. Validation

- [x] 5.1 Run `just check` and confirm no evaluation errors on both profiles
- [x] 5.2 Run `nix fmt --check` (or `nix fmt` to fix) across changed `.nix`
  files
- [x] 5.3 Run `nix flake check ./nix` and confirm it passes
- [x] 5.4 Manually verify `./init.sh --email you@example.com` writes
  `.local/git-email` correctly and is git-ignored (`git status` shows clean)
- [x] 5.5 Manually verify `require_email` blocks bootstrap/deploy stages when
  `.local/git-email` is absent, and unblocks once set
- [x] 5.6 Review full diff and show to maintainer before committing
