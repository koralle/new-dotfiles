# Renovate × mise セットアップ設計

日付: 2026-07-18  
ステータス: 承認済み（実装待ち）

## 背景

`new-dotfiles` は mise でツールバージョンを管理している。  
pin 済みツールの更新を自動化したい。Dependabot は mise 非対応のため、Renovate の mise manager を使う。

## ゴール

- mise で pin しているツールの新バージョンを、PR 経由で自動提案する
- レビューしやすいよう、ツールごとに 1 PR とする
- このリポジトリの conf.d 配置でも確実に検出できる

## 非ゴール

- brew bootstrap パッケージ（`mise.toml` の `[bootstrap.packages]`）の更新
- Nix / flake.lock の更新
- GitHub Actions の更新
- `latest` / `lts` / `nightly` などの浮動バージョンの固定化・更新
- automerge

## 現状

| パス | 内容 | Renovate 対象 |
|------|------|---------------|
| `mise.toml` | settings / dotfiles / bootstrap | いいえ（`[tools]` なし） |
| `src/dotfiles/modules/mise/conf.d/00_runtime.toml` | rust/node/deno/bun（浮動） | 実質いいえ |
| `src/dotfiles/modules/mise/conf.d/01_cargo.toml` | cargo ツール（pin） | はい |
| `src/dotfiles/modules/mise/conf.d/02_github.toml` | github ツール（pin） | はい |
| `src/dotfiles/modules/mise/conf.d/03_npm.toml` | npm/pnpm ツール（pin） | はい |

注意: Renovate デフォルトの conf.d パターンは `**/.config/mise/conf.d/*.toml` のみ。  
このリポジトリの `src/dotfiles/modules/mise/conf.d/*.toml` はデフォルトでは拾えないため、`managerFilePatterns` を明示する。

## アプローチ

**B. このリポジトリ向け調整版** を採用。

- Mend Renovate GitHub App
- ルートに `renovate.json`
- `enabledManagers: ["mise"]` のみ
- conf.d パスを明示
- ツールごと個別 PR（デフォルト動作を維持）

## アーキテクチャ

```
GitHub repo
  ├── renovate.json          # Renovate 設定
  └── src/dotfiles/modules/mise/conf.d/*.toml
           ▲
           │ スキャン & 更新 PR
Mend Renovate App (GitHub)
```

1. App が定期的にリポジトリをスキャン
2. mise manager が conf.d 内の pin 済みツールを検出
3. 新バージョンがあればツールごとに PR を作成
4. 人がレビューしてマージ

## 設定内容

### `renovate.json`

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "enabledManagers": ["mise"],
  "mise": {
    "managerFilePatterns": [
      "**/mise.toml",
      "**/.mise.toml",
      "**/mise/conf.d/*.toml",
      "**/.config/mise/conf.d/*.toml"
    ]
  }
}
```

`config:recommended` のデフォルトで依存ごと 1 PR になるため、group 設定は置かない。

### 手動セットアップ（コード外）

1. [Mend Renovate](https://github.com/apps/renovate) を `koralle/new-dotfiles` にインストール
2. 初回 onboarding PR（または設定反映後の初回 run）を確認
3. pin 済みツールの更新 PR が期待どおり出ることを確認

## 成功条件

- `01_cargo.toml` / `02_github.toml` / `03_npm.toml` の pin ツールが検出される
- 更新があるツールごとに独立した PR が開く
- 他 manager（npm 単独、github-actions 等）は動かない
- `00_runtime.toml` の浮動バージョンは触られない

## リスクと注意

| リスク | 対応 |
|--------|------|
| conf.d パス未検出 | `managerFilePatterns` に `**/mise/conf.d/*.toml` を追加 |
| backend 未対応ツール | Renovate mise manager の対応 backend を確認（cargo/github/npm は対応） |
| App 未インストール | 実装後に手動インストールが必要 |

## 実装スコープ

1. `renovate.json` を追加
2. （任意）セットアップ手順を短いメモとして残す場合は design か README に 1 段落

コード変更の本体は `renovate.json` 1 ファイル。
