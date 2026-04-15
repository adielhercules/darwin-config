## 1. Configuration Setup

- [x] 1.1 Locate the home-manager git configuration module in the nix-darwin config
- [x] 1.2 Add `init.defaultBranch = "main"` to `programs.git.extraConfig` section
- [x] 1.3 Verify the configuration syntax in the nix file

## 2. Activation and Verification

- [x] 2.1 Run `home-manager switch` to activate the configuration changes
- [x] 2.2 Verify the setting with `git config --global init.defaultBranch` (should output `main`)
- [x] 2.3 Create a test repository with `git init test-repo` and verify the default branch is `main` with `git branch`

## 3. Testing and Validation

- [x] 3.1 Test in multiple directories to ensure global configuration is applied
- [x] 3.2 Verify existing repositories are unaffected by the change
- [x] 3.3 Confirm configuration persists after system restart
