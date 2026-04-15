## 1. Refactor init.sh into stage functions

- [x] 1.1 Extract path substitution (sed) logic into `run_paths_sed` function
- [x] 1.2 Extract git hook activation into `run_git` function
- [x] 1.3 Create `run_paths` function that calls `run_paths_sed` then `run_git`
- [x] 1.4 Extract bootstrap deploy into `run_bootstrap` function
- [x] 1.5 Extract standard deploy into `run_deploy` function

## 2. Add CLI flag parsing and dispatch

- [x] 2.1 Add `case "$1"` argument parsing block after function definitions
- [x] 2.2 Wire `--paths` to call `run_paths`
- [x] 2.3 Wire `--git` to call `run_git`
- [x] 2.4 Wire `--bootstrap` to call `run_bootstrap`
- [x] 2.5 Wire `--deploy` to call `run_deploy`
- [x] 2.6 Wire `--all` to call `run_paths`, `run_bootstrap`, `run_deploy` in order
- [x] 2.7 Wire empty/no-arg case to behave identically to `--all`
- [x] 2.8 Add `*` catch-all case that prints usage to stderr and exits non-zero
