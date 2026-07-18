# Mac ホストシステム設定移植設計

日付: 2026-07-18  
ステータス: 承認済み（実装待ち）  
参考: https://github.com/koralle/dotfiles/tree/main/hosts/koralle-macbookair  
前提: `docs/superpowers/specs/2026-07-18-mise-brew-to-nix-design.md` 実装済み

## 背景

`new-dotfiles` の `src/nix/hosts/koralle-macbookair` は、Homebrew casks と最小 nix 設定のみを持つ。  
旧 `koralle/dotfiles` の同ホストには、Finder / DNS / TouchID / fonts / Tailscale など OS 寄りの設定が揃っている。

CLI ツールの多くは既に `src/dotfiles/modules/mise/conf.d/` で入れているため、Nix で二重インストールしない。

## ゴール

- 旧ホスト設定のうち **システム設定中心** を `src/nix/hosts/koralle-macbookair` に移植する
- 旧 repo と同じファイル分割（environment / fonts / networking / security / services / system）
- GUI casks を一部追加する（firefox, raycast, zed, tailscale-app）
- `gh` を home-manager から Homebrew brew に移す
- mise conf.d 管理ツールは Nix で再インストールしない

## 非ゴール

- `programs.fish` / `programs.zsh` の system 側設定（dotfiles 側に任せる）
- `launchd`（podman-machine 等）
- `user.packages` の CLI 拡充（qemu, zellij, podman 等）
- mise conf.d ツールの Nix 化
- homebrew brews への mise / herdr / marksman 等の追加
- 旧 homebrew casks の全移植（obsidian, discord 追加分, podman-desktop 等）
- `system.stateVersion` の 6 → 7 上げ
- Linux / マルチホスト

## 現状

### ホスト（移植先）

```
src/nix/hosts/koralle-macbookair/
  default.nix    # nix settings + homebrew import + users.home + system.stateVersion=6
  homebrew.nix   # casks: ghostty, google-chrome, opencode-desktop, discord, aerospace
```

### home-manager

`src/nix/modules/flake.nix` の `home.packages`: `tig`, `gh`, `fish`

### mise conf.d（Nix で入れない）

| ソース | ツール |
|--------|--------|
| `00_runtime.toml` | rust, node, deno, bun |
| `01_cargo.toml` | just, zoxide, fd-find, ripgrep, bat, eza, starship, sheldon |
| `02_github.toml` | herdr, fzf, podman |
| `03_npm.toml` | npm, pnpm, @antfu/ni, difit, fish-lsp, yaml-language-server, opencode-ai |

## 方針（承認済み）

1. **システム設定中心**: environment / fonts / networking / security / system / services.tailscale
2. **ファイル分割**: 旧 repo と同じ 1 責務 1 ファイル
3. **casks 追加**: firefox, raycast, zed, tailscale-app のみ
4. **gh 移動**: `home.packages` → `homebrew.brews`
5. **mise 重複禁止**: conf.d に載るものは Nix packages / homebrew に載せない
6. **stateVersion**: 現行 `6` を維持

## アーキテクチャ

```
darwinConfigurations.koralle-macbookair
  └─ src/nix/hosts/koralle-macbookair
       ├─ default.nix       # imports + nix + hostPlatform
       ├─ environment.nix   # systemPackages + env vars
       ├─ fonts.nix
       ├─ homebrew.nix      # casks + brew:gh
       ├─ networking.nix
       ├─ security.nix
       ├─ services.nix      # tailscale
       └─ system.nix        # stateVersion + primaryUser + defaults
  └─ home-manager
       └─ home.packages     # tig, fish（gh 削除）
```

### パッケージ配置（最終）

| パッケージ | 配置 | 備考 |
|------------|------|------|
| git, vim, wget, jq, gnupg | `environment.systemPackages` | 旧 environment.nix 準拠 |
| fonts 一式 | `fonts.packages` | 旧 fonts.nix 準拠 |
| ghostty, google-chrome, opencode-desktop, discord, aerospace | `homebrew.casks` | 既存 |
| firefox, raycast, zed, tailscale-app | `homebrew.casks` | 今回追加 |
| gh | `homebrew.brews` | home-manager から移動 |
| tig, fish | `home.packages` | 既存維持 |
| tailscale service | `services.tailscale` | cask の tailscale-app と併用 |

### mise 除外（明示）

以下は **Nix にも homebrew にも載せない**:

- ripgrep, eza, fd, zoxide, bat, fzf, podman, herdr
- just, starship, sheldon
- rust, node, deno, bun
- npm/pnpm/ni/difit/fish-lsp/yaml-language-server/opencode-ai

旧 `user.nix` の qemu / podman / podman-compose / zellij / zoxide / bat / fzf / ripgrep / eza / fd は移植しない。

## ファイル構成

```
src/nix/hosts/koralle-macbookair/
  default.nix
  environment.nix   # 新規
  fonts.nix         # 新規
  homebrew.nix      # 変更
  networking.nix    # 新規
  security.nix      # 新規
  services.nix      # 新規
  system.nix        # 新規
src/nix/modules/flake.nix  # gh 削除
```

`flake.nix`（ルート）は変更不要。

## 詳細仕様

### `default.nix`

- imports: environment, fonts, homebrew, networking, security, services, system
- 維持: `nix.optimise`, `nix.settings`, `nixpkgs.hostPlatform`
- `users.users.${username}.home` は維持（home-manager 必須）
- `system.stateVersion` / `primaryUser` は `system.nix` に移す（default は薄い orchestrator）

### `environment.nix`

旧設定どおり:

```nix
environment = {
  systemPackages = with pkgs; [ git vim wget jq gnupg ];
  variables = {
    COLORTERM = "truecolor";
    EDITOR = "nvim";
    XDG_CONFIG_HOME = "/Users/${username}/.config";
    XDG_CACHE_HOME = "/Users/${username}/.cache";
    XDG_DATA_HOME = "/Users/${username}/.local/share";
    XDG_STATE_HOME = "/Users/${username}/.local/state";
  };
};
```

### `fonts.nix`

```nix
fonts.packages = with pkgs; [
  moralerspace
  hackgen-font
  jetbrains-mono
  nerd-fonts.jetbrains-mono
  udev-gothic
  udev-gothic-nf
  ibm-plex
];
```

### `networking.nix`

```nix
networking = {
  hostName = "${username}-macbookair";
  localHostName = "${username}-mac";
  knownNetworkServices = [ "Wi-Fi" "Ethernet Adaptor" "Thunderbolt Ethernet" ];
  dns = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
};
```

### `security.nix`

```nix
security.pam.services.sudo_local.touchIdAuth = true;
```

### `services.nix`

```nix
services.tailscale = {
  enable = true;
  package = pkgs.tailscale;
};
```

### `system.nix`

- `system.stateVersion = 6`（現行維持。旧 repo の 7 には上げない）
- `system.primaryUser = username`
- defaults: controlcenter / finder / menuExtraClock / SoftwareUpdate / screensaver  
  （旧 `system.nix` と同じ値）

### `homebrew.nix`

- `enable = true`
- `onActivation`: autoUpdate / upgrade / cleanup = "uninstall"（既存）
- `brews = [ "gh" ]`
- `casks`: 既存 5 + firefox / raycast / zed / tailscale-app

### `src/nix/modules/flake.nix`

- `home.packages` から `gh` を削除
- 残す: `tig`, `fish`

## 検証

1. `nix build .#darwinConfigurations.koralle-macbookair.system`（または `darwin-rebuild build --flake .#koralle-macbookair`）が通る
2. 追加ファイルに mise conf.d ツールが含まれないこと（目視）
3. `home.packages` に `gh` が無いこと、`homebrew.brews` に `gh` があること

## リスクと注意

- **hostname 変更**: `networking.hostName` 適用でマシン名が変わる。意図どおり。
- **Tailscale 二重経路**: cask `tailscale-app`（GUI）と `services.tailscale`（nix パッケージ）を併用。旧設定と同じ。問題が出たら後続で整理。
- **fonts パッケージ名**: nixpkgs の属性名が変わっている場合は build 時に修正する。
- **stateVersion**: 6 のまま。上げる判断は別タスク。
