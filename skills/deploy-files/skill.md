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

- **Operator handoff:** every response that ends a turn follows the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — terse output; approvals under `**Needs your approval:**` citing `path:L<n>`; questions numbered under `**Needs your answer:**`; exactly one `**Next step:**` command; one line when nothing is needed (Form A). Decisions and questions never mixed; empty sections omitted.

---

## Parse invocation

| User says | Direction | Mode |
|-----------|-----------|------|
| `@deploy-files` | in-place (cwd is target) | copy no-overwrite + scaffold no-overwrite |
| `@deploy-files update` | in-place (cwd is target) | copy no-overwrite + scaffold no-overwrite + **rules-aware merge** + **`opencode.json --sync-paths`** + **`cursorrules-verify.sh --fix`** (sister cells) |
| `@deploy-files copy - /path/to/repo` | outbound (source = this repo) | copy no-overwrite to `/path/to/repo/.ai` |
| `@deploy-files copy - /path/to/repo --force` | outbound | copy with idempotent overwrite of existing files (legacy) |
| `@deploy-files status` | report | `.ai/skills` presence + `.cursorrules` verification (via `cursorrules-verify.sh`) + `opencode.json` presence |

**Argument equivalence (script + this table):** verbs accept the `--` prefix or bare form — `update` ≡ `--update`, `status` ≡ `--status`, `force` ≡ `--force`. `copy` is the explicit form of the default copy mode. A `-` / `--` token is a separator and is dropped. The target path may appear in any position: `@deploy-files copy - /path` ≡ `@deploy-files /path` ≡ `@deploy-files -- /path copy`.

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
| Project-root `standards/.gitkeep`, `docs/integration/.gitkeep` | skip (preserve) — **deprecated paths; use `.work/standards/` + `.work/docs/integration/`** (bootstrap no longer creates repo-root dirs) |
| `.cursorrules` | skip (preserve) |
| `DOCS_TECH_STACK.md` | skip (preserve) |
| `opencode.json` | create if missing via `install-opencode-config.sh`; on `--update` run `--sync-paths` only (`.opencode/` MCP dir never touched) |

---

## I3 — update-merge protocol (`@deploy-files update` only)

After I1 (no-overwrite copy) the script:

1. Prints a **merge candidate list** for differing files under `.ai/` (the vendored fat-client copy — never `.work/standards/` or `.work/docs/integration/`, which are project memory and never merge candidates).
2. Runs **`install-opencode-config.sh --sync-paths`** on the consumer repo root (fat-client `.ai/skills` paths; preserves custom `mcp` entries).
3. Runs **`cursorrules-verify.sh --fix`** on the consumer root when a `.cursorrules` exists — repairs sister-framework cells (fills installed-sister tokens, re-points stale baked absolutes) — and reports the verification verdict. (Thin-client source-pointer/script-path repair is `@deploy-basic update`'s domain.)
4. The **agent** performs rules-aware merge for each `.ai/` merge candidate (agent work, not script work).

**Framework-owned file classes** (all paths relative to `<target>/.ai/`; merge applies; preserve target customizations):

| Class | Examples | Merge rule |
|-------|----------|------------|
| Skills | `.ai/skills/<skill>/skill.md`, `reference.md` | Append new sections/rules absent in target; update shared sections where source changed; **never** drop target-only verbs/tables/notes |
| Standards (vendored copy, template/example docs) | `.ai/standards/*.md` | Append new sections; update shared section text where source changed; preserve dated target overrides. **Not** `.work/standards/*.md` the target generates for itself via `@plan-foundation` — that tree is never a merge candidate. |
| Framework docs | `.ai/README.md`, `.ai/PROCESS_ROUTER.md`, `.ai/START_HERE.md`, `.ai/concepts/`, `.ai/docs/guides/` | Append new sections; update shared paragraphs where source changed; preserve target examples/paths |
| Templates | `.ai/templates/**` | Prefer source version (templates are framework-owned); but if target edited a template intentionally, keep target + record in report |
| Scripts | `.ai/scripts/**` | Prefer source version (mechanical); overwrite target copy → record in report |

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
| 7 | Scaffold ran **into target** (in-place only); target `.work/` + `.cursorrules` + empty `.work/standards/` + `.work/docs/integration/` present | |
| 8 | `update`: merge candidate list processed; each merged file recorded; no wholesale replaces | |
| 9 | User informed of next steps | |

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

## Next commands (in target project)

```text
@session-control start
```

(In-place `@deploy-files` already scaffolded `.work/` + `.cursorrules`; `@project-bootstrap init` is only needed for the outbound `copy - <path>` direction.)

Any operator-required approval or question raised anywhere in the report must ALSO appear in the closing handoff block (enumerated, with `path:line`), not only in this section. End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

---

## Coding-agent config (tool-agnostic)

Agent OS skills and standards are **tool-agnostic** — they are plain markdown invoked by name (`@session-control`, `@deploy-files`, …). Each coding agent still needs a **host config** so it loads the right instructions and skill paths:

| Agent | Config file | What Agent OS uses it for |
|-------|-------------|---------------------------|
| **opencode** | `opencode.json` (repo root) | `instructions`, `skills.paths`, optional `mcp` |
| **Cursor** | `.cursorrules` (repo root) | Agent rules; optional `.cursor/mcp.json` for MCP |
| **Claude Code** | `.claude/settings.json` or `.claude/mcp.json` | MCP registration |
| **Codex / other** | per tool docs | Provide skill paths + rules equivalent to `.cursorrules` |

**After deploy (operator checklist):**

1. **All agents:** ensure `.cursorrules` exists (scaffold creates it in-place; outbound needs `@project-bootstrap init`).
2. **opencode users:** if `opencode.json` is missing, run:
   ```bash
   REPO_ROOT="$(pwd)" bash .ai/scripts/install-opencode-config.sh
   # thin-client (no local .ai/): bash "$AGENT_OS_SOURCE/scripts/install-opencode-config.sh"
   ```
   Review paths: **fat-client** → `.ai/skills`, `.ai/START_HERE.md`; **thin-client** → absolute `$AGENT_OS_SOURCE/skills`.
3. **MCP (optional):** `@project-query-setup install` detects `opencode.json`, `.cursor/mcp.json`, etc. and registers `tools-project` after operator confirmation.
4. **Verify:** invoke `@session-control start` from your agent — it should load `.ai/skills/session-control/skill.md` (fat) or `$AGENT_OS_SOURCE/skills/session-control/skill.md` (thin).