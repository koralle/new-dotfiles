# mise Homebrew → Nix 移行設計

日付: 2026-07-18  
ステータス: 承認済み（実装待ち）  
参考: https://github.com/koralle/dotfiles

## 背景

`new-dotfiles` は GUI / 一部 CLI を `mise.toml` の `[bootstrap.packages]`（Homebrew / brew-cask）で入れている。  
AeroSpace は third-party tap で、mise の brew-cask が要求する `api/cask/<token>.json` を公開していないためインストールできない。

参考リポジトリ `koralle/dotfiles` は **nix-darwin + nix-homebrew** で cask を宣言し、CLI は `home.packages`（nixpkgs）に載せている。

## ゴール

- `mise.toml` の Homebrew 経由パッケージをすべてやめる
- 同等のパッケージを Nix 宣言で入れる（nix-darwin / nix-homebrew / home-manager）
- AeroSpace を `nikitabobko/tap` 経由で入れられるようにする
- mise は **dotfiles シンボリックリンク** 専用として残す

## 非ゴール

- macOS system defaults / fonts / networking など参考 repo 全体の移植
- Aerospace 設定ファイル（`aerospace.toml`）の追加
- mise conf.d（cargo/github/npm/runtime）ツールの Nix 化
- マルチホスト構成（`hosts/` の本格分割）
- flake-parts の維持
- Linux / NixOS 対応

## 現状

### mise bootstrap（移行元）

| キー | バージョン | 種別 |
|------|------------|------|
| `brew:gh` | `2.96.0` | formula |
| `brew:fish` | `4.8.1` | formula |
| `brew-cask:ghostty` | `latest` | cask |
| `brew-cask:google-chrome` | `latest` | cask |
| `brew-cask:opencode-desktop` | `latest` | cask |
| `brew-cask:discord` | `latest` | cask |

### Nix（移行先の土台）

- `flake.nix`: `homeConfigurations.koralle` のみ（flake-parts）
- `nix-darwin` input はあるが未使用
- `home.packages`: `tig` のみ
- `programs.neovim`: nightly overlay

### ビルドフロー（現状）

```
just build
  1) mise bootstrap          # brew packages + dotfiles
  2) home-manager switch     # tig + neovim
```

## 方針（承認済み）

1. **アプローチ A（最小追加）**: `darwinConfigurations` を 1 ホスト追加し、参考 repo の必要部分だけ移植する
2. **パッケージ範囲**: 現行 6 + Aerospace
3. **mise**: `[bootstrap.packages]` 削除、`[dotfiles]` は維持

## アーキテクチャ

```
just build
  1) mise bootstrap                 # dotfiles シンボリックリンクのみ
  2) sudo darwin-rebuild switch     # パッケージ + home-manager
       └─ nix-darwin (koralle-macbookair)
            ├─ nix-homebrew
            │    taps: homebrew-core, homebrew-cask, nikitabobko/homebrew-tap
            ├─ homebrew.casks       # GUI
            └─ home-manager (user: koralle)
                 ├─ home.packages   # gh, fish, tig
                 └─ programs.neovim # 既存
```

### パッケージ配置

| パッケージ | 配置 | 備考 |
|------------|------|------|
| `gh` | `home.packages` | nixpkgs |
| `fish` | `home.packages` | nixpkgs。ログインシェル化は今回しない |
| `tig` | `home.packages` | 既存のまま |
| `ghostty` | `homebrew.casks` | |
| `google-chrome` | `homebrew.casks` | |
| `opencode-desktop` | `homebrew.casks` | |
| `discord` | `homebrew.casks` | |
| `aerospace` | `homebrew.casks` | `nikitabobko/tap/aerospace` + tap input |

## ファイル構成

```
flake.nix
justfile
mise.toml
src/nix/
  hosts/koralle-macbookair/
    default.nix      # host の最小 nix 設定 + homebrew import
    homebrew.nix     # homebrew enable / casks / onActivation
  modules/
    flake.nix        # home.packages に gh, fish を追加（tig 継続）
    neovim/          # 既存
```

ホスト名 `koralle-macbookair` は参考 repo と実機 hostname に合わせる。

## 詳細仕様

### `flake.nix`

- flake-parts と単独 `homeConfigurations` を廃止
- **inputs**:
  - `nixpkgs` (nixpkgs-unstable)
  - `nix-darwin` (master, nixpkgs follows)
  - `home-manager` (nixpkgs follows)
  - `neovim-nightly-overlay` (既存、nixpkgs follows)
  - `nix-homebrew`
  - `homebrew-core` / `homebrew-cask` / `homebrew-tap`（`flake = false`）
- **outputs**: `darwinConfigurations.koralle-macbookair` のみ
- modules 配線（参考 repo 準拠）:
  - host module: `./src/nix/hosts/koralle-macbookair`
  - `nix-homebrew.darwinModules.nix-homebrew` + taps 設定
  - `homebrew.taps = builtins.attrNames config.nix-homebrew.taps`
  - `home-manager.darwinModules.home-manager`
  - `home-manager.users.koralle` → `./src/nix/modules/flake.nix`
- `system = "aarch64-darwin"`, `username = "koralle"`
- `users.users.koralle.home = "/Users/koralle"` を設定（home-manager 必須）

### `src/nix/hosts/koralle-macbookair/homebrew.nix`

```nix
homebrew = {
  enable = true;
  onActivation = {
    autoUpdate = true;
    upgrade = true;
    cleanup = "uninstall";
  };
  brews = [ ];
  casks = [
    { name = "ghostty"; }
    { name = "google-chrome"; }
    { name = "opencode-desktop"; }
    { name = "discord"; }
    { name = "nikitabobko/tap/aerospace"; }
  ];
};
```

### `src/nix/hosts/koralle-macbookair/default.nix`

- `imports = [ ./homebrew.nix ];`
- `nix.settings.experimental-features = "nix-command flakes";`
- `nixpkgs.hostPlatform = "aarch64-darwin";`
- `system.stateVersion` は nix-darwin 必須値を設定（参考: `6`）
- `system.primaryUser = "koralle";`（必要なら）

### `src/nix/modules/flake.nix`

- 既存 neovim import 維持
- `home.username` / `home.homeDirectory` をここに移す（現行は root flake の homeConfigurations 側で設定）
- `home.packages` に `tig`, `gh`, `fish` を列挙
- `extraSpecialArgs` で `inputs` / `username` を渡す（neovim-nightly overlay 用）

### `justfile`

```just
alias b := build

build:
  @mise bootstrap
  @sudo darwin-rebuild switch --flake .#koralle-macbookair
```

### `mise.toml`

- `[bootstrap.packages]` セクション削除
- `[bootstrap.brew.taps]` セクション削除
- `[settings]` / `[dotfiles]` は変更しない

## ビルドフロー（移行後）

```
just build
  1) mise bootstrap          # dotfiles のみ
  2) darwin-rebuild switch   # nix-homebrew + casks + home-manager packages
```

初回は `nix-darwin` 未導入の場合、参考 repo の `bootstrap-macbookair.sh` と同様に  
`nix run nix-darwin -- switch --flake .#koralle-macbookair` が必要になり得る。  
justfile は導入済みを前提とし、初回手順は実装時に必要なら README / コメントで補足する。

## リスクと緩和

| リスク | 緩和 |
|--------|------|
| `cleanup = "uninstall"` が既存 brew を消す | 意図どおり declarative。必要なら実装前に `brew list` を確認 |
| fish がログインシェルにならない | 今回は package のみ。シェル変更は別タスク |
| 既存 `homeConfigurations` 利用者 | 出力を darwin に一本化。`home-manager switch --flake .#koralle` は使えなくなる |
| flake.lock が大きく増える | homebrew-core/cask を input にするため想定内 |

## 成功条件

1. `mise.toml` に brew / brew-cask パッケージが無い
2. `darwinConfigurations.koralle-macbookair` が評価できる
3. 宣言上、対象 7 パッケージ（6 + aerospace）が Nix 経由で入る
4. `just build` が mise bootstrap（dotfiles）+ darwin-rebuild を実行する
5. 既存 neovim / tig / dotfiles リンクが壊れていない

## 実装メモ

- スタイルは参考 `koralle/dotfiles` の `homebrew.nix` / root `flake.nix` に寄せる
- Aerospace の **設定** は別タスク（dotfiles module + mise symlink または home-manager `xdg.configFile`）
- Renovate 設計書の「brew bootstrap は対象外」は、移行後は「Nix / homebrew 宣言は対象外」のまま維持でよい
