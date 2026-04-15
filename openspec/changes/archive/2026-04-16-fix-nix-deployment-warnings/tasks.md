## 1. Replace nixfmt-classic with nixfmt

- [x] 1.1 In `nix/darwin/home.nix`, replace `nixfmt-classic` with `nixfmt` in `home.packages`
- [x] 1.2 In `nix/modules/home/neovim.nix`, replace `nixfmt-classic` with `nixfmt` in the package list

## 2. Fix deprecated system attribute in overlays

- [x] 2.1 In `nix/darwin/default.nix`, replace `final.system` with `final.stdenv.hostPlatform.system` in the nixpkgs-unstable import expression
- [x] 2.2 In `nix/darwin/default.nix`, replace `prev.system` with `prev.stdenv.hostPlatform.system` in the zjstatus package reference

## 3. Fix git signing format warning

- [x] 3.1 In `nix/darwin/home.nix`, add `signing.format = null;` inside the `programs.git` block

## 4. Fix GTK4 theme warning

- [x] 4.1 In `nix/darwin/home.nix`, add `gtk.gtk4.theme = null;` to the home-manager config

## 5. Bump home.stateVersion

- [x] 5.1 In `nix/darwin/home.nix`, change `home.stateVersion` from `"24.11"` to `"25.05"`

## 6. Verify

- [x] 6.1 Run `darwin-rebuild switch` and confirm none of the five warning classes appear in the output
- [x] 6.2 Confirm neovim, git, and zellij launch and function correctly after the switch
