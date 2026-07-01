---
name: deploy-files
description: >-
  Deploy .ai (Agent OS) files into a target project. Two directions: (1) in-place
  bootstrap — invoked from a TARGET project, copies the source .ai in without
  overwriting existing files, then scaffolds .work/ + .cursorrules; (2) outbound
  copy — invoked from the source Agent OS repo, copies into an explicit <path>.
  `update` mode additionally performs a rules-aware merge of existing-but-
  differing files (append new rules, update shared sections, preserve target
  customizations + REPLACE: tokens; never wholesale-replace). Copies only
  git-tracked / non-ignored files (anything in .gitignore is never copied).
  Use deploy-files (default), deploy-files update, deploy-files copy - <path>,
  deploy-files status.
---

# deploy-files

Two-direction deploy of the `.ai` framework into a target project so the project can use Agent OS skills. **Default = no-overwrite**: existing target files are preserved by construction.

**Shell:** `bash <source>/.ai/scripts/deploy-files.sh <target-path> [mode]`
**Scaffold shell:** `REPO_ROOT=<target> bash <source>/.ai/templates/bootstrap.sh`

**Canonical path:** `.ai/skills/deploy-files/skill.md` · **Shell:** `.ai/scripts/deploy-files.sh`

**Security invariant:** The script enumerates files via `git ls-files --cached --others --exclude-standard` from the **source** `.ai` repo root, so anything `.gitignore` excludes (credentials, private context, `tmp/`, …) is never copied — enforced by construction, not a hand-maintained list. The source must be a git repo with `.ai/` as its root.

**Source not modified.** deploy-files only writes to the **target**. The source `.ai` is read-only (script enumerates it via `git ls-files`).

**Contrast with `deploy-repo`:** `deploy-files` copies only the `.ai/` directory (no VCS artifacts). Use `@deploy-repo clone` when you need the full repo including `.git` and `.github/`.

---

## Parse invocation

| User says | Direction | Mode |
|-----------|-----------|------|
| `@deploy-files` | in-place (cwd is target) | copy no-overwrite + scaffold no-overwrite |
| `@deploy-files update` | in-place (cwd is target) | copy no-overwrite + scaffold no-overwrite + **rules-aware merge** of differing existing files |
| `@deploy-files copy - /path/to/repo` | outbound (source = this repo) | copy no-overwrite to `/path/to/repo/.ai` |
| `@deploy-files copy - /path/to/repo --force` | outbound | copy with idempotent overwrite of existing files (legacy) |
| `@deploy-files status` | report | report whether `.ai/` exists at known deploy locations |

**Default:** `status` if no verb matches; if invoked bare with no `.ai/` in cwd → in-place bootstrap (`copy` in-place per § I0).

**Aliases:** `bootstrap`, `in-place` → bare `@deploy-files`.

---

## I0 — Pre-checks (both directions)

| Condition | Action |
|-----------|--------|
| Source is not a git repo, or `.ai/` is not the git root | **Block**: report; deploy-files relies on `git ls-files` as the authority |
| Target parent dir does not exist | **Block**: report missing path |
| Destination exists and is not a dir | **Block**: report conflict |
| Destination already has `.ai/` | Proceed with **no-overwrite**; report skipped count (default) |
| `--force` requested and destination populated | Warn that target customizations will be overwritten; require explicit `--force` in the same invocation |

### Source resolution (in-place direction)

When invoked from a **target** project (cwd has no `.ai/scripts/deploy-files.sh`):

1. **Auto:** if the script can be located at a known source path (user named it, or sibling `.ai` discoverable per `.cursorrules` § Frameworks registry auto-discovery from `.ai` parent), use it.
2. **Ask once:** if source is unknown, ask the user for the source `.ai` path (e.g. `/mnt/work/Projects/.ai`). Do not guess.
3. **Optional skills path override:** user may name a skills location (`/path/.ai/skills`); default is `<source>/.ai/skills`. Recorded in the start report only; the script enumerates the whole source, so an explicit skills path is informational unless the user wants a partial deploy (then surface as **Unverified — partial deploy unsupported by script**).
4. Source determined → run the shell from the **target** directory:
   ```bash
   cd <target> && bash <source>/scripts/deploy-files.sh . <mode>
   # or override source via env:
   AI_SOURCE=<source> bash <source>/scripts/deploy-files.sh . <mode>
   ```

---

## I1 — Copy mode (no-overwrite by default)

1. `bash <source>/.ai/scripts/deploy-files.sh "<resolved-target>"` (default) — or `--force` / `--update` per parse-invocation.
2. **File set:** `git ls-files --cached --others --exclude-standard` from the source repo root — i.e. every file **not** excluded by `.gitignore`. Anything gitignored (`.credentials/`, `.private/`, `tmp/`, …) is never copied.
3. **Skill-level omissions** (intentional, on top of the git-based set): `.github/`, `.gitignore`, `.gitattributes`, `.cursorrules`, `scripts/deploy-files.sh`, `scripts/deploy-repo.sh` (the deploy scripts themselves — run from source repo, not consumer concern).
4. **No-overwrite default:** `rsync --ignore-existing` skips any file already present in the target. Target-side customizations are preserved by construction. `--force` drops that flag (legacy idempotent overwrite; still no `--delete`). `--update` keeps no-overwrite and additionally emits the **merge candidate list** (existing-but-differing files) for § I3.

---

## I2 — Scaffold (in-place direction only)

When invoked in-place (bare `@deploy-files` or `@deploy-files update`), after the copy pass run the `.work/` + `.cursorrules` + `DOCS_TECH_STACK.md` scaffold **into the target** using the source templates (no-overwrite — `bootstrap.sh` uses `copy_if_missing`):

```bash
REPO_ROOT="$(pwd)" bash <source>/.ai/templates/bootstrap.sh
```

This is the same scaffold `@project-bootstrap init` performs; in-place `@deploy-files` simply chains it so the target ends with `.ai/` + `.work/` + `.cursorrules` in one invocation. **Outbound `copy - <path>` does NOT scaffold** — it leaves next-step instructions for the user to run `@project-bootstrap init` in the target (preserves the legacy contract).

Scaffold honor table (no-overwrite):

| Target path | If exists |
|-------------|-----------|
| `.work/**` skeleton files | skip (preserve) |
| `.cursorrules` | skip (preserve) |
| `DOCS_TECH_STACK.md` | skip (preserve) |

---

## I3 — update-merge protocol (`@deploy-files update` only)

After I1 (no-overwrite copy) the script prints a **merge candidate list**: every file present in both source and target whose content differs. The agent then performs a **rules-aware merge** for each candidate. This is agent work, not script work.

**Framework-owned file classes** (merge applies; preserve target customizations):

| Class | Examples | Merge rule |
|-------|----------|------------|
| Skills | `skills/<skill>/skill.md`, `reference.md` | Append new sections/rules absent in target; update shared sections where source changed; **never** drop target-only verbs/tables/notes |
| Standards | `standards/*.md` | Append new sections; update shared section text where source changed; preserve dated target overrides |
| Framework docs | `README.md`, `PROCESS_ROUTER.md`, `START_HERE.md`, `concepts/`, `docs/guides/` | Append new sections; update shared paragraphs where source changed; preserve target examples/paths |
| Templates | `templates/**` | Prefer source version (templates are framework-owned); but if target edited a template intentionally, keep target + record in report |
| Scripts | `scripts/**` | Prefer source version (mechanical); overwrite target copy → record in report |

**Preserve invariants (never drop):**
- Target `REPLACE:` tokens the user has filled (the merge must keep target values, not source `REPLACE:*` placeholders).
- Target-only skill folders not present in source (custom skills).
- Target additions to any table (rows the source doesn't have).
- Target date-stamped filenames (`YYYYMMDD-*`).

**Merge procedure per candidate:**
1. Read source version and target version.
2. Diff structurally (sections by `##`/`###` headings, then list rows / table rows).
3. For each **shared** section whose source text changed: apply source change **but** keep target-only rows/lines inside it.
4. For each **source-only** section absent in target: append it.
5. For each **target-only** section absent in source: keep unchanged.
6. Write merged result to target. Record `merged: <path>` in the report.
7. **Never** wholesale-replace a file the target already owned.

**Unverified, do not merge blindly:** binary files, lockfiles, anything under `tmp/`. Report and skip.

---

## Completion

| # | Check | Result |
|---|-------|--------|
| 1 | Source repo is a git repo with `.ai/` as root | pass |
| 2 | Destination `.ai/` exists after copy | |
| 3 | No `.gitignored` content in destination (`.credentials/`, `.private/`, `tmp/`, …) | |
| 4 | `.github/` excluded from destination | |
| 5 | `.cursorrules` excluded from copy (created by scaffold or `@project-bootstrap init`) | |
| 6 | No-overwrite honored (skipped count reported; `--force` only when explicitly requested) | |
| 7 | Scaffold ran **into target** (in-place only); target `.work/` + `.cursorrules` present | |
| 8 | `update`: merge candidate list processed; each merged file recorded; no wholesale replaces | |
| 9 | User informed of next steps | |

## Next commands (in target project)

```text
@session-control start
```

(In-place `@deploy-files` already scaffolded `.work/` + `.cursorrules`; `@project-bootstrap init` is only needed for the outbound `copy - <path>` direction.)