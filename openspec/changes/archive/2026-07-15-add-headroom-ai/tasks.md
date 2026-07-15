## 1. Create headroom Home Manager module

- [x] 1.1 Create `nix/modules/home/headroom.nix` with `home.packages = [ pkgs.uv ]` and `home.activation.uvInstallHeadroomAi` activation script that runs `uv tool install "headroom-ai[all]"`

## 2. Wire module into home.nix

- [x] 2.1 Add import for `./../../modules/home/headroom.nix` in `nix/darwin/home.nix` alongside other tool modules (rtk, opencode, etc.)

## 3. Verify

- [x] 3.1 Run `darwin-rebuild switch` and confirm no eval errors
- [x] 3.2 Verify `uv --version` works in a new shell
- [x] 3.3 Verify `headroom --version` works in a new shell
