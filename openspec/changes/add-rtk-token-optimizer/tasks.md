## 1. Install rtk via Homebrew

- [x] 1.1 Add `"rtk"` to `homebrew.brews` list in `nix/darwin/default.nix`

## 2. Create Home Manager module

- [x] 2.1 Create `nix/modules/home/rtk.nix` with `home.activation.rtkInitOpencode` entry (`entryAfter [ "writeBoundary" ]`) that runs `rtk init -g --opencode`, guarded by `command -v rtk`
- [x] 2.2 Add `home.activation.rtkInitCopilot` entry (`entryAfter [ "writeBoundary" ]`) that runs `rtk init -g --copilot`, guarded by `command -v rtk`

## 3. Wire module into config

- [x] 3.1 Add `../modules/home/rtk.nix` to the `imports` list in `nix/darwin/home.nix`

## 4. Deploy and verify

- [x] 4.1 Run `darwin-rebuild switch` (or `just deploy`) to install rtk and trigger activation
- [x] 4.2 Verify installation: `rtk --version` returns a valid version
- [x] 4.3 Verify hooks: `rtk init --show` confirms both OpenCode and Copilot hooks are active
