# Renovate × mise Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Renovate config so pin-backed mise tools under `src/dotfiles/modules/mise/conf.d/` get one-PR-per-tool updates via the Mend Renovate GitHub App.

**Architecture:** Single root `renovate.json` enables only the `mise` manager and extends file patterns to cover this repo’s `**/mise/conf.d/*.toml` layout (default Renovate patterns only match under `.config/mise/conf.d/`). Runtime floating versions (`latest`/`lts`/`nightly`) stay as-is; brew bootstrap and Nix stay out of scope.

**Tech Stack:** Renovate (Mend GitHub App), mise config TOML, JSON config

**Spec:** `docs/superpowers/specs/2026-07-18-renovate-mise-design.md`

---

## File map

| File | Action | Responsibility |
|------|--------|----------------|
| `renovate.json` | Create | Renovate project config (mise-only, conf.d patterns) |
| (GitHub UI) | Manual | Install Mend Renovate App on `koralle/new-dotfiles` |

No application code, tests, or mise tool version changes in this plan.

---

### Task 1: Add `renovate.json`

**Files:**
- Create: `renovate.json`

- [ ] **Step 1: Create the config file**

Create `renovate.json` at the repository root with exactly:

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

- [ ] **Step 2: Validate JSON syntax**

Run:

```bash
python3 -m json.tool renovate.json > /dev/null && echo "JSON OK"
```

Expected: `JSON OK` (exit code 0)

- [ ] **Step 3: Confirm target files exist for the custom pattern**

Run:

```bash
ls -1 src/dotfiles/modules/mise/conf.d/*.toml
```

Expected (at least):

```
src/dotfiles/modules/mise/conf.d/00_runtime.toml
src/dotfiles/modules/mise/conf.d/01_cargo.toml
src/dotfiles/modules/mise/conf.d/02_github.toml
src/dotfiles/modules/mise/conf.d/03_npm.toml
```

These match `**/mise/conf.d/*.toml`. Pin-backed deps live in `01_` / `02_` / `03_`; `00_runtime.toml` uses floating versions and will not produce meaningful version bumps.

- [ ] **Step 4: Commit**

```bash
git add renovate.json
git commit -m "$(cat <<'EOF'
feat: add Renovate config for mise tools

Enable mise manager only and match conf.d paths used by this repo.
EOF
)"
```

---

### Task 2: Manual Mend Renovate App install (operator)

**Files:**
- None (GitHub settings only)

This task is **manual** — the agent cannot complete it without browser/GitHub App permissions. Document completion status for the human operator.

- [ ] **Step 1: Install the app**

1. Open https://github.com/apps/renovate
2. Install / configure for account `koralle`
3. Grant access to repository `koralle/new-dotfiles` (selected repos or all)

- [ ] **Step 2: Push config if not already on remote**

If `renovate.json` commit is only local:

```bash
git push -u origin HEAD
```

- [ ] **Step 3: Trigger / wait for first run**

After install + push, Renovate typically:

1. Opens an onboarding PR **or**
2. Runs against existing `renovate.json` and opens dependency update PRs

Check the repo’s Pull requests tab and https://developer.mend.io/ (Renovate dashboard) for job status.

- [ ] **Step 4: Verify success criteria from the spec**

| Check | Expected |
|-------|----------|
| Managers | Only mise-related PRs (no npm-as-standalone manager floods, no Actions-only noise) |
| Sources | Updates touch `01_cargo.toml` / `02_github.toml` / `03_npm.toml` when newer versions exist |
| PR shape | One tool ≈ one PR |
| Floating | No PR rewriting `latest` / `lts` / `nightly` in `00_runtime.toml` as real pins |

If conf.d files are not detected, re-check `mise.managerFilePatterns` includes `**/mise/conf.d/*.toml` and that the App has repo access.

- [ ] **Step 5: No further commit required**

App install leaves no git artifact. Optional note only if the human wants a short ops checklist elsewhere — out of scope unless requested.

---

## Self-review (plan vs spec)

| Spec requirement | Task |
|------------------|------|
| Mend Renovate GitHub App | Task 2 |
| Root `renovate.json` | Task 1 |
| `enabledManagers: ["mise"]` only | Task 1 Step 1 |
| conf.d path `**/mise/conf.d/*.toml` | Task 1 Step 1 |
| One PR per tool (default, no groups) | Task 1 (no packageRules groups) |
| No brew / Nix / Actions / automerge | Out of config → satisfied by enabledManagers + no extra keys |
| Floating versions untouched | Implicit (no pin conversion task) |

No placeholders remaining. Scope is intentionally one config file + operator install.
