# Mac Host System Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port system-focused macOS host settings from `koralle/dotfiles` into `src/nix/hosts/koralle-macbookair`, add selected Homebrew casks, move `gh` to brew, and never reinstall mise conf.d tools via Nix.

**Architecture:** Split host config into one-file-per-concern modules (environment, fonts, networking, security, services, system) imported by `default.nix`. Homebrew stays declarative via nix-homebrew; CLI runtimes remain mise-managed.

**Tech Stack:** nix-darwin, nix-homebrew, home-manager, nixpkgs-unstable

**Spec:** `docs/superpowers/specs/2026-07-18-mac-host-system-settings-design.md`

**Reference:** https://github.com/koralle/dotfiles/tree/main/hosts/koralle-macbookair

---

## File map

| File | Action | Responsibility |
|------|--------|----------------|
| `src/nix/hosts/koralle-macbookair/environment.nix` | Create | systemPackages + env vars |
| `src/nix/hosts/koralle-macbookair/fonts.nix` | Create | fonts.packages |
| `src/nix/hosts/koralle-macbookair/networking.nix` | Create | hostname + DNS |
| `src/nix/hosts/koralle-macbookair/security.nix` | Create | TouchID sudo |
| `src/nix/hosts/koralle-macbookair/services.nix` | Create | tailscale service |
| `src/nix/hosts/koralle-macbookair/system.nix` | Create | stateVersion + primaryUser + defaults |
| `src/nix/hosts/koralle-macbookair/homebrew.nix` | Modify | brews: gh; casks: +firefox/raycast/zed/tailscale-app |
| `src/nix/hosts/koralle-macbookair/default.nix` | Modify | import all modules; drop system block |
| `src/nix/modules/flake.nix` | Modify | remove `gh` from home.packages |

Out of scope: programs.fish/zsh, launchd, user.packages CLI expansion, mise conf.d tools, flake.nix root rewrite.

**mise conf.d tools — must NOT appear in any Nix host file:**

rust, node, deno, bun, just, zoxide, fd-find/fd, ripgrep, bat, eza, starship, sheldon, herdr, fzf, podman, npm, pnpm, @antfu/ni, difit, fish-lsp, yaml-language-server, opencode-ai

---

### Task 1: Create environment.nix

**Files:**
- Create: `src/nix/hosts/koralle-macbookair/environment.nix`

- [ ] **Step 1: Create the file**

Create `src/nix/hosts/koralle-macbookair/environment.nix` with exactly:

```nix
{ pkgs, username, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      git
      vim
      wget
      jq
      gnupg
    ];

    variables = {
      COLORTERM = "truecolor";
      EDITOR = "nvim";
      XDG_CONFIG_HOME = "/Users/${username}/.config";
      XDG_CACHE_HOME = "/Users/${username}/.cache";
      XDG_DATA_HOME = "/Users/${username}/.local/share";
      XDG_STATE_HOME = "/Users/${username}/.local/state";
    };
  };
}
```

- [ ] **Step 2: Verify no mise tools**

```bash
rg -n 'ripgrep|eza|zoxide|fd|bat|fzf|podman|herdr|just|starship|sheldon' src/nix/hosts/koralle-macbookair/environment.nix
```

Expected: no matches

- [ ] **Step 3: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/environment.nix
git commit -m "feat(host): add environment.nix system packages and XDG vars"
```

---

### Task 2: Create fonts.nix

**Files:**
- Create: `src/nix/hosts/koralle-macbookair/fonts.nix`

- [ ] **Step 1: Create the file**

Create `src/nix/hosts/koralle-macbookair/fonts.nix` with exactly:

```nix
{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      moralerspace
      hackgen-font
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      udev-gothic
      udev-gothic-nf
      ibm-plex
    ];
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/fonts.nix
git commit -m "feat(host): add fonts.nix packages"
```

---

### Task 3: Create networking.nix

**Files:**
- Create: `src/nix/hosts/koralle-macbookair/networking.nix`

- [ ] **Step 1: Create the file**

Create `src/nix/hosts/koralle-macbookair/networking.nix` with exactly:

```nix
{ username, ... }:
{
  networking = {
    hostName = "${username}-macbookair";
    localHostName = "${username}-mac";

    knownNetworkServices = [
      "Wi-Fi"
      "Ethernet Adaptor"
      "Thunderbolt Ethernet"
    ];

    dns = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/networking.nix
git commit -m "feat(host): add networking.nix hostname and DNS"
```

---

### Task 4: Create security.nix

**Files:**
- Create: `src/nix/hosts/koralle-macbookair/security.nix`

- [ ] **Step 1: Create the file**

Create `src/nix/hosts/koralle-macbookair/security.nix` with exactly:

```nix
{ ... }:
{
  security.pam.services.sudo_local.touchIdAuth = true;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/security.nix
git commit -m "feat(host): enable TouchID for sudo"
```

---

### Task 5: Create services.nix

**Files:**
- Create: `src/nix/hosts/koralle-macbookair/services.nix`

- [ ] **Step 1: Create the file**

Create `src/nix/hosts/koralle-macbookair/services.nix` with exactly:

```nix
{ pkgs, ... }:
{
  services = {
    tailscale = {
      enable = true;
      package = pkgs.tailscale;
    };
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/services.nix
git commit -m "feat(host): enable Tailscale service"
```

---

### Task 6: Create system.nix

**Files:**
- Create: `src/nix/hosts/koralle-macbookair/system.nix`

- [ ] **Step 1: Create the file**

Create `src/nix/hosts/koralle-macbookair/system.nix` with exactly:

```nix
{ username, ... }:
{
  system = {
    stateVersion = 6;
    primaryUser = username;

    defaults = {
      controlcenter = {
        AirDrop = false;
        BatteryShowPercentage = false;
        Bluetooth = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        ShowRemovableMediaOnDesktop = false;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };

      menuExtraClock = {
        Show24Hour = true;
        ShowDate = 0;
        ShowDayOfMonth = true;
        ShowDayOfWeek = true;
        ShowSeconds = false;
      };

      SoftwareUpdate = {
        AutomaticallyInstallMacOSUpdates = false;
      };

      screensaver = {
        askForPassword = true;
      };
    };
  };
}
```

Note: `stateVersion = 6` (current value). Do **not** raise to 7.

- [ ] **Step 2: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/system.nix
git commit -m "feat(host): add system.nix defaults and stateVersion"
```

---

### Task 7: Wire imports in default.nix

**Files:**
- Modify: `src/nix/hosts/koralle-macbookair/default.nix`

- [ ] **Step 1: Replace default.nix contents**

Overwrite `src/nix/hosts/koralle-macbookair/default.nix` with exactly:

```nix
{ username, ... }:
{
  imports = [
    ./environment.nix
    ./fonts.nix
    ./homebrew.nix
    ./networking.nix
    ./security.nix
    ./services.nix
    ./system.nix
  ];

  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      sandbox = true;
    };
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.${username}.home = "/Users/${username}";
}
```

- [ ] **Step 2: Confirm system block moved**

```bash
rg -n 'stateVersion|primaryUser' src/nix/hosts/koralle-macbookair/
```

Expected:
- matches only in `system.nix`
- **no** matches in `default.nix`

- [ ] **Step 3: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/default.nix
git commit -m "feat(host): import system modules in default.nix"
```

---

### Task 8: Expand homebrew.nix (casks + gh brew)

**Files:**
- Modify: `src/nix/hosts/koralle-macbookair/homebrew.nix`

- [ ] **Step 1: Replace homebrew.nix contents**

Overwrite `src/nix/hosts/koralle-macbookair/homebrew.nix` with exactly:

```nix
{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    brews = [
      # GitHub CLI
      # https://cli.github.com/
      "gh"
    ];

    casks = [
      {
        # Ghostty
        # https://github.com/ghostty-org/ghostty
        name = "ghostty";
      }
      {
        # Google Chrome
        name = "google-chrome";
      }
      {
        # OpenCode Desktop
        name = "opencode-desktop";
      }
      {
        # Discord
        name = "discord";
      }
      {
        # Aerospace
        # https://github.com/nikitabobko/AeroSpace
        name = "nikitabobko/tap/aerospace";
      }
      {
        # Firefox
        # https://github.com/mozilla-firefox/firefox
        name = "firefox";
      }
      {
        # Raycast
        # https://www.raycast.com/
        name = "raycast";
      }
      {
        # Zed
        # https://github.com/zed-industries/zed
        name = "zed";
      }
      {
        # Tailscale
        name = "tailscale-app";
      }
    ];
  };
}
```

- [ ] **Step 2: Verify no mise-overlap brews**

```bash
rg -n 'mise|herdr|marksman|podman|fzf|ripgrep|eza|zoxide|fd|bat' src/nix/hosts/koralle-macbookair/homebrew.nix
```

Expected: no matches (only `gh` and GUI casks)

- [ ] **Step 3: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/homebrew.nix
git commit -m "feat(host): add gh brew and selected casks"
```

---

### Task 9: Remove gh from home-manager packages

**Files:**
- Modify: `src/nix/modules/flake.nix`

- [ ] **Step 1: Update home.packages**

Overwrite `src/nix/modules/flake.nix` with exactly:

```nix
{
  inputs,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./neovim/flake.nix
  ];

  programs = {
    home-manager = {
      enable = true;
    };
  };

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "26.11";

    packages = with pkgs; [
      # https://github.com/jonas/tig
      tig

      # https://fishshell.com/
      fish
    ];
  };
}
```

- [ ] **Step 2: Confirm gh only in homebrew**

```bash
rg -n '\bgh\b' src/nix/
```

Expected:
- `src/nix/hosts/koralle-macbookair/homebrew.nix` contains `"gh"`
- `src/nix/modules/flake.nix` does **not** contain `gh`

- [ ] **Step 3: Commit**

```bash
git add src/nix/modules/flake.nix
git commit -m "refactor: move gh from home-manager to Homebrew"
```

---

### Task 10: Build verification

**Files:**
- None (verify only)

- [ ] **Step 1: Eval/build darwin configuration**

```bash
nix build .#darwinConfigurations.koralle-macbookair.system --no-link
```

Expected: succeeds (exit 0).  
If a font attribute is missing/renamed in nixpkgs, fix only that attribute name in `fonts.nix` and re-run. Do not add packages outside the spec.

Alternative if the above attr path fails on this nix-darwin version:

```bash
darwin-rebuild build --flake .#koralle-macbookair
```

Expected: succeeds (exit 0)

- [ ] **Step 2: Final mise-overlap scan across host modules**

```bash
rg -n 'ripgrep|zoxide|fd-find|\bfd\b|bat|eza|fzf|podman|herdr|starship|sheldon|just|opencode-ai|fish-lsp' src/nix/hosts/koralle-macbookair/
```

Expected: no matches for tool installs (comments mentioning names are also discouraged; ideally zero hits)

- [ ] **Step 3: Commit any build-driven fixes (only if needed)**

If fonts or option names required fixes:

```bash
git add src/nix/hosts/koralle-macbookair/
git commit -m "fix(host): adjust package/option names for nixpkgs"
```

If no fixes were needed, skip this commit.

---

## Spec coverage checklist

| Spec requirement | Task |
|------------------|------|
| environment.nix (packages + XDG) | Task 1 |
| fonts.nix | Task 2 |
| networking.nix | Task 3 |
| security.nix TouchID | Task 4 |
| services.tailscale | Task 5 |
| system.nix defaults + stateVersion 6 | Task 6 |
| default.nix imports + thin orchestrator | Task 7 |
| homebrew casks firefox/raycast/zed/tailscale-app | Task 8 |
| homebrew brew gh | Task 8 |
| remove gh from home.packages | Task 9 |
| no mise conf.d tools in Nix | Tasks 1, 8, 10 |
| build verification | Task 10 |
| no programs.fish/zsh | (omitted by design) |
| no launchd | (omitted by design) |
| no user.packages CLI expansion | (omitted by design) |
