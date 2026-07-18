# mise Homebrew → Nix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move all `mise.toml` `[bootstrap.packages]` Homebrew installs to nix-darwin + nix-homebrew + home-manager, and add AeroSpace via `nikitabobko/tap`.

**Architecture:** Replace standalone `homeConfigurations` with one `darwinConfigurations.koralle-macbookair`. GUI apps become declarative Homebrew casks (managed by nix-homebrew); `gh`/`fish`/`tig` go in `home.packages`. mise keeps only dotfile symlinks.

**Tech Stack:** nix-darwin, nix-homebrew, home-manager, nixpkgs-unstable, mise (dotfiles only)

**Spec:** `docs/superpowers/specs/2026-07-18-mise-brew-to-nix-design.md`

**Reference:** https://github.com/koralle/dotfiles (`flake.nix`, `hosts/koralle-macbookair/homebrew.nix`)

---

## File map

| File | Action | Responsibility |
|------|--------|----------------|
| `src/nix/hosts/koralle-macbookair/homebrew.nix` | Create | casks + onActivation |
| `src/nix/hosts/koralle-macbookair/default.nix` | Create | host nix settings + import homebrew |
| `flake.nix` | Rewrite | darwinConfiguration + nix-homebrew + home-manager |
| `src/nix/modules/flake.nix` | Modify | username/home + `gh`/`fish` packages |
| `mise.toml` | Modify | remove bootstrap packages/taps |
| `justfile` | Modify | `darwin-rebuild` instead of `home-manager switch` |
| `flake.lock` | Update | lock new inputs (via `nix flake update` / first eval) |

Out of scope files: Aerospace config, system defaults, fonts, mise conf.d tools.

---

### Task 1: Create host Homebrew module

**Files:**
- Create: `src/nix/hosts/koralle-macbookair/homebrew.nix`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p src/nix/hosts/koralle-macbookair
```

Create `src/nix/hosts/koralle-macbookair/homebrew.nix` with exactly:

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

    brews = [ ];

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
    ];
  };
}
```

- [ ] **Step 2: Verify file exists**

```bash
test -f src/nix/hosts/koralle-macbookair/homebrew.nix && echo OK
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/homebrew.nix
git commit -m "feat: add nix-darwin homebrew casks module"
```

---

### Task 2: Create host default module

**Files:**
- Create: `src/nix/hosts/koralle-macbookair/default.nix`

- [ ] **Step 1: Create host entry module**

Create `src/nix/hosts/koralle-macbookair/default.nix` with exactly:

```nix
{ username, ... }:
{
  imports = [
    ./homebrew.nix
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

  system = {
    stateVersion = 6;
    primaryUser = username;
  };
}
```

- [ ] **Step 2: Verify import path resolves**

```bash
test -f src/nix/hosts/koralle-macbookair/default.nix && \
test -f src/nix/hosts/koralle-macbookair/homebrew.nix && echo OK
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add src/nix/hosts/koralle-macbookair/default.nix
git commit -m "feat: add koralle-macbookair host module"
```

---

### Task 3: Update home-manager module packages

**Files:**
- Modify: `src/nix/modules/flake.nix`

- [ ] **Step 1: Replace module contents**

Overwrite `src/nix/modules/flake.nix` with:

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

      # https://cli.github.com/
      gh

      # https://fishshell.com/
      fish
    ];
  };
}
```

- [ ] **Step 2: Confirm neovim module still expects `inputs`**

```bash
rg -n "inputs" src/nix/modules/neovim/flake.nix
```

Expected: line using `inputs.neovim-nightly-overlay` (must remain wired via `extraSpecialArgs` in root flake).

- [ ] **Step 3: Commit**

```bash
git add src/nix/modules/flake.nix
git commit -m "feat: manage gh and fish via home.packages"
```

---

### Task 4: Rewrite root `flake.nix` for nix-darwin

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Replace root flake**

Overwrite `flake.nix` with:

```nix
{
  description = "koralle's Nix Flakes";

  inputs = {
    # nixpkgs-unstable
    # https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    # nix-darwin
    # https://github.com/nix-darwin/nix-darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager
    # https://github.com/nix-community/home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # neovim-nightly-overlay
    # https://github.com/nix-community/neovim-nightly-overlay
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-homebrew
    # https://github.com/zhaofengli/nix-homebrew
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # homebrew-core
    # https://github.com/Homebrew/homebrew-core
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    # homebrew-cask
    # https://github.com/Homebrew/homebrew-cask
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # nikitabobko/homebrew-tap (Aerospace)
    # https://github.com/nikitabobko/homebrew-tap
    homebrew-tap = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-tap,
      home-manager,
      ...
    }:
    let
      username = "koralle";
      system = "aarch64-darwin";
    in
    {
      darwinConfigurations."koralle-macbookair" = nix-darwin.lib.darwinSystem {
        inherit system;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };

        specialArgs = {
          inherit username;
        };

        modules = [
          ./src/nix/hosts/koralle-macbookair

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = username;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "nikitabobko/homebrew-tap" = homebrew-tap;
              };
              mutableTaps = true;
            };
          }

          (
            { config, ... }:
            {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
            }
          )

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs username;
            };
            home-manager.users.${username} = import ./src/nix/modules/flake.nix;
          }
        ];
      };
    };
}
```

- [ ] **Step 2: Update flake lock (fetch new inputs)**

```bash
nix flake update
```

Expected: completes without error; `flake.lock` gains `nix-homebrew`, `homebrew-core`, `homebrew-cask`, `homebrew-tap` (and may drop `flake-parts` if unused).

Note: first run can take several minutes (homebrew-core/cask are large).

- [ ] **Step 3: Evaluate darwin configuration (no switch yet)**

```bash
nix eval .#darwinConfigurations.koralle-macbookair.config.system.stateVersion
```

Expected: `6`

- [ ] **Step 4: Confirm casks are in the evaluated config**

```bash
nix eval .#darwinConfigurations.koralle-macbookair.config.homebrew.casks --json
```

Expected JSON array including objects/names for `ghostty`, `google-chrome`, `opencode-desktop`, `discord`, and `nikitabobko/tap/aerospace` (exact JSON shape may be list of attrsets or strings depending on nix-darwin version — all five names must appear).

- [ ] **Step 5: Confirm home packages include gh/fish/tig**

```bash
nix eval .#darwinConfigurations.koralle-macbookair.config.home-manager.users.koralle.home.packages --apply 'ps: map (p: p.pname or p.name) ps' 
```

If that fails due to package attr shape, use:

```bash
nix build .#darwinConfigurations.koralle-macbookair.config.system.build.toplevel --dry-run
```

Expected: dry-run succeeds (or prints derivation paths) without evaluation errors about missing modules/args.

- [ ] **Step 6: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat: switch to nix-darwin with nix-homebrew"
```

---

### Task 5: Remove mise bootstrap packages

**Files:**
- Modify: `mise.toml`

- [ ] **Step 1: Edit mise.toml**

Overwrite `mise.toml` so it contains only settings + dotfiles (no bootstrap package sections):

```toml
[settings]
dotfiles.root = "~/.dotfiles"

[dotfiles]
"~/.dotfiles" = "src/dotfiles"
"~/.zshrc" = "src/dotfiles/modules/zsh/zshrc"
"~/.config/ghostty/config" = "src/dotfiles/modules/ghostty/config"
"~/.config/herdr/config.toml" = "src/dotfiles/modules/herdr/config.toml"
"~/.config/sheldon/plugins.toml" = "src/dotfiles/modules/sheldon/plugins.toml"
"~/.config/mise/conf.d/*.toml" = "src/dotfiles/modules/mise/conf.d/*.toml"
"~/.config/fish/config.fish" = "src/dotfiles/modules/fish/config.fish"
"~/.config/fish/conf.d/*.fish" = "src/dotfiles/modules/fish/conf.d/*.fish"
"~/.config/eza/theme.yaml" = "src/dotfiles/modules/eza/theme.yaml"
"~/.config/opencode/opencode.jsonc" = "src/dotfiles/modules/opencode/opencode.jsonc"
"~/.config/tig/config" = "src/dotfiles/modules/tig/config"
```

- [ ] **Step 2: Verify no brew package keys remain**

```bash
rg -n 'bootstrap\.(packages|brew)|brew:|brew-cask:' mise.toml || echo "clean"
```

Expected: `clean` (no matches)

- [ ] **Step 3: Commit**

```bash
git add mise.toml
git commit -m "chore: remove mise Homebrew bootstrap packages"
```

---

### Task 6: Update justfile build target

**Files:**
- Modify: `justfile`

- [ ] **Step 1: Replace justfile**

Overwrite `justfile` with:

```just
alias b := build

build:
  @mise bootstrap
  @sudo darwin-rebuild switch --flake .#koralle-macbookair
```

- [ ] **Step 2: Show recipe**

```bash
just --list
```

Expected: includes `build` (and alias `b` if listed).

- [ ] **Step 3: Commit**

```bash
git add justfile
git commit -m "feat: build via darwin-rebuild instead of home-manager"
```

---

### Task 7: End-to-end verification

**Files:**
- None (verification only)

- [ ] **Step 1: Static checks**

```bash
# 1) no mise brew packages
rg -n 'brew:|brew-cask:' mise.toml || echo "mise brew clean"

# 2) darwin config evaluates
nix eval .#darwinConfigurations.koralle-macbookair.config.system.stateVersion

# 3) homebrew enabled
nix eval .#darwinConfigurations.koralle-macbookair.config.homebrew.enable

# 4) cask names present
nix eval .#darwinConfigurations.koralle-macbookair.config.homebrew.casks --json | tee /tmp/casks.json
rg -n 'ghostty|google-chrome|opencode-desktop|discord|aerospace' /tmp/casks.json

# 5) justfile points at darwin-rebuild
rg -n 'darwin-rebuild|koralle-macbookair' justfile
```

Expected:
- `mise brew clean`
- stateVersion `6`
- homebrew.enable `true`
- all five cask names matched
- justfile contains `darwin-rebuild` and `koralle-macbookair`

- [ ] **Step 2: Optional live switch (requires user machine + sudo)**

Only if the user wants a real install on this Mac:

```bash
# First-time nix-darwin (if darwin-rebuild not on PATH yet):
# nix run nix-darwin -- switch --flake .#koralle-macbookair

just build
```

Expected: mise links dotfiles; darwin-rebuild applies system + home-manager + casks without error.

Verify after switch:

```bash
command -v gh
command -v fish
command -v tig
ls /Applications/Ghostty.app /Applications/AeroSpace.app 2>/dev/null || true
brew list --cask 2>/dev/null | rg -n 'ghostty|google-chrome|opencode-desktop|discord|aerospace' || true
```

- [ ] **Step 3: No extra commit unless verification fixed something**

If Step 1 found issues, fix in a follow-up commit. If clean, done.

---

## Spec coverage checklist

| Spec requirement | Task |
|------------------|------|
| Remove mise `[bootstrap.packages]` | Task 5 |
| gh/fish via home.packages | Task 3 |
| GUI casks via homebrew | Task 1 |
| Aerospace + nikitabobko tap | Task 1, Task 4 |
| nix-darwin + nix-homebrew wiring | Task 4 |
| host module files | Task 1–2 |
| justfile uses darwin-rebuild | Task 6 |
| mise keeps dotfiles only | Task 5 |
| Evaluate/success criteria | Task 7 |
| No Aerospace config / system defaults | Out of scope (no tasks) |

## Notes for implementers

- `cleanup = "uninstall"` will remove Homebrew packages not declared in this config. Intentional per spec.
- `homeConfigurations.koralle` is removed; do not document old `home-manager switch --flake .#koralle` as the primary path.
- Do not add Aerospace `aerospace.toml` in this plan.
- Prefer frequent commits exactly as task steps specify.
