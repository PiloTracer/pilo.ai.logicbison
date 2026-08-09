---
name: deploy-basic
description: >-
  Thin-client bootstrap of Agent OS into a target project. Copies ONLY the
  minimal scaffold — .cursorrules (with AGENT_OS_SOURCE pointer to the source
  .ai), .work/ skeleton, DOCS_TECH_STACK.md. Framework assets (skills,
  standards, concepts, docs/guides, scripts) are NOT copied; the agent resolves
  them from the source Agent OS at runtime per .cursorrules § Source resolution.
  Use deploy-basic (default), deploy-basic update, deploy-basic status, or
  deploy-basic - <target-path> (outbound from source). Never modifies the source.
  Contrast with deploy-files (full fat-client copy of .ai/).
---

# deploy-basic

Thin-client deploy of the `.ai` framework. The target project receives only the scaffold it owns (`.cursorrules`, `.work/`, `DOCS_TECH_STACK.md`); everything else (skills, standards, concepts, docs/guides, scripts, templates) stays in the **source** `.ai` and is loaded on demand via the `AGENT_OS_SOURCE` pointer written into `.cursorrules`.

**Shell:** `bash <source>/.ai/scripts/deploy-basic.sh <target-path> [mode]`

**Canonical path:** `.ai/skills/deploy-basic/skill.md` · **Shell:** `.ai/scripts/deploy-basic.sh`

**Source not modified.** deploy-basic only writes to the **target**. The source `.ai` is read-only (script reads its templates).

**Contrast with `deploy-files`:** `deploy-files` = **fat-client** (vendored full `.ai/` into target, skills are local). `deploy-basic` = **thin-client** (skills remote in source). Choose:
- `deploy-files` — you want skills/standards/concepts versioned inside the project, offline-editable, no external dependency.
- `deploy-basic` — you want the project to track the live source framework, share one source of truth across many consumer repos, and accept new skills/standards automatically by updating the source (no per-project re-deploy).

---

## Parse invocation

| User says | Direction | Mode |
|-----------|-----------|------|
| `@deploy-basic - /path/to/target` | outbound (invoked from source) | thin bootstrap no-overwrite |
| `@deploy-basic` (from target, post-bootstrap) | in-place | re-runs no-overwrite bootstrap + source-pointer sync |
| `@deploy-basic status` | report | read-only: `.cursorrules` verification (via `cursorrules-verify.sh`: `AGENT_OS_SOURCE`, gate-table script-path baking, sister-framework cells), `.work/`, fat-client leak, **`opencode.json` path drift** |
| `@deploy-basic update` (from target) | in-place | no-overwrite + re-sync `AGENT_OS_SOURCE` + re-bake script paths + **repair sister-framework cells** (`cursorrules-verify.sh --fix`) + **`opencode.json --sync-paths`** + merge candidate list |
| `@deploy-basic /path/to/target --update` | outbound | same as `update` — target path may appear in any position |

**Argument equivalence (script + this table):** verbs accept the `--` prefix or bare form — `update` ≡ `--update`, `status` ≡ `--status`, `force` ≡ `--force`. A `-` / `--` token is a separator and is dropped. The target path may appear in any position relative to the verb: `@deploy-basic "/path" update` is 100% identical to `@deploy-basic /path --update`.

**Default:** `status` if no verb matches. **Aliases:** `bootstrap-thin`, `thin` → bare `@deploy-basic`.

**Target path is REQUIRED when invoked from the source Agent OS dir (Scenario #2 / outbound).** The shell aborts with a usage message if no `<target-path>` is supplied; the agent must prompt the user for it rather than guessing. When invoked in-place (target is cwd), the path is implicit (`.`) and no argument is needed.

---

## What gets copied (the local surface)

| Path | Source | If target exists |
|------|--------|-------------------|
| `.cursorrules` | `templates/cursorrules.template` with `AGENT_OS_SOURCE=<source>` substituted | skip (preserve); `--force` overwrites |
| `.work/README.md`, `.work/context/HANDOFF.md`, `.work/plans/NEXT.md`, `.work/plans/ASSUMPTIONS.md`, `.work/plans/RISK_REGISTRY.md`, `.work/plans/UNKNOWNS.md`, `.work/decisions/README.md`, `.work/prompts/README.md`, `.work/features/README.md`, `.work/docs/README.md`, `.work/docs/features/README.md` | `templates/work/*.template` (suffix stripped) | skip (preserve) |
| `.work/plans/{foundation,full,operations,proposals,archives}/.gitkeep`, `.work/{analysis,scripts}/`, `.work/docs/{guides,tutorials,reference,integration}/.gitkeep`, `.work/standards/.gitkeep` | created empty (directories populated later with README.md or generated content) | skip (preserve) |
| `DOCS_TECH_STACK.md` | `templates/DOCS_TECH_STACK.md.template` | skip (preserve) |
| `opencode.json` | `opencode.json.template` via `install-opencode-config.sh` | **Bootstrap:** create if missing. **Update:** `--sync-paths` only (framework paths); never `--force` unless operator requests. **`.opencode/` MCP dir:** never touched — use `@project-query-setup`. |
| **Local `.ai/` directory** | **never created** | n/a — thin-client only; skills resolve from `$AGENT_OS_SOURCE` |

**Explicitly NOT copied (stay in source, loaded at runtime):** `skills/**`, source `standards/**` (the framework's template/example docs), `concepts/**`, `docs/guides/**` (workflow guides), `scripts/**`, `templates/**`, `SKILL_DEPENDENCIES.md`, root `README.md`, `PROCESS_ROUTER.md`, `START_HERE.md`, `.github/`, `.gitignore`, `.gitattributes`. Do not confuse framework source `standards/` with `.work/standards/` — the latter is the target's **own** future deliverables under project memory, never sourced from or synced with the framework.

---

## I0 — Pre-checks

| Condition | Action |
|-----------|--------|
| Source `templates/cursorrules.template` missing | **Block**: source is not a valid `.ai` framework root |
| Target dir does not exist | **Block**: report missing path |
| Target already has local `.ai/skills/` | **Warn** fat-client leak: target was previously bootstrapped fat; thin-client would duplicate. Ask user to confirm intent (proceed leaves the local `.ai/` in place — deploy-basic does not delete it). |
| Target `.cursorrules` exists + lacks `AGENT_OS_SOURCE=` line | In `update` mode → flag as **MERGE CANDIDATE** (the Source-resolution section is missing); in default mode → skip (preserve) and report that source-resolution is not wired. |

---

## I1 — Bootstrap protocol

1. Resolve source `AI_ROOT` (explicit `AI_SOURCE` env, else script's parent). Validate `templates/cursorrules.template` exists.
2. Resolve target = `REPO_ROOT` of the consumer (cwd for in-place, or the named path for outbound).
3. Write `.cursorrules` into the target from the template, substituting `AGENT_OS_SOURCE=REPLACE_BASICSOURCE` → `AGENT_OS_SOURCE=<absolute AI_ROOT>`. **No-overwrite** if `.cursorrules` exists; `--force` overwrites.
4. Run the `.work/` + `DOCS_TECH_STACK.md` scaffold via `BOOTSTRAP_SKIP_CURSERRULES=1 REPO_ROOT=<target> bash <source>/templates/bootstrap.sh` (bootstrap's `copy_if_missing` enforces no-overwrite; the env flag keeps it from re-writing `.cursorrules` that we just wrote with the substituted pointer).
5. Report: source pointer value, `.work/` presence, fat-client leak check, next steps.

**Idempotent re-run.** Safe to re-run; no-overwrite preserves target customizations. The source pointer is re-synced only in `update` mode (or `--force`).

---

## I2 — update-merge protocol (`@deploy-basic update` only)

After I1 (no-overwrite) the script:

1. **Repairs the source pointer + baked paths** via `cursorrules-verify.sh --fix --thin` (idempotent, in-place, preserves all other target edits and filled `REPLACE:` tokens): re-syncs a stale `AGENT_OS_SOURCE` (e.g. source moved), re-bakes gate-table script paths (literal `.ai/scripts/` or stale absolute prefix → current `$AGENT_OS_SOURCE/scripts/`), and **repairs sister-framework cells** — fills still-open `REPLACE:AI_*_PATH` tokens for sisters now installed on disk, re-points stale baked sister absolutes.
2. **Syncs `opencode.json` framework paths** via `install-opencode-config.sh --sync-paths` (updates `instructions`, `references`, `skills.paths` when they point at the old source; **preserves** `mcp` blocks and operator-added entries). If paths remain stale → listed as merge candidate.
3. **Lists merge candidates** among the local surface: existing-but-differing files vs the current source templates (substituted). Candidates:
   - `.cursorrules` (differs from current `template-with-source`)
   - `.work/<file>` (target has user content; templates are skeletons)
   - `DOCS_TECH_STACK.md` (preserve target stack pins)
   - `opencode.json` (paths still stale after `--sync-paths`)
4. The **agent** then performs a rules-aware merge per candidate (this is agent work, not script work).

### Merge rules per file class

| Class | Merge rule |
|-------|------------|
| `.cursorrules` | Update framework sections (Skills table, Core principles, Protected files, **Source resolution** section, Frameworks registry). Preserve target-filled `REPLACE:` tokens, target customizations, target-specific protected-file paths. If target lacks the Source-resolution section entirely (fat-client template) → append it with the current `AGENT_OS_SOURCE`. Never wholesale-replace. |
| `.work/<file>` skeletons | Append new template sections absent in target; **preserve all user content** (HANDOFF rows, NEXT iteration blocks, UNKNOWNS entries). Skeletons are minimal — most merges add no new sections. Never drop target rows. |
| `.work/<dir>/.gitkeep` + new scaffold dirs | Create any NEW scaffold dir that didn't exist (e.g. a new framework sub-dir added since last bootstrap); do not touch existing. |
| `DOCS_TECH_STACK.md` | Preserve target stack pins; append new template-only sections if any. Never replace user values. |
| `opencode.json` | **Script `--sync-paths`** updates framework path fields when `AGENT_OS_SOURCE` moved. **Agent merge** if still stale: align `skills.paths` / `instructions` with current source; preserve custom `mcp`, extra `instructions`, operator-added `references`. Never `--force` unless operator explicitly requests full regenerate. |

### Preserve invariants (never drop)
- Target's filled `REPLACE:` tokens (the merge keeps target values, not source `REPLACE:*` placeholders).
- Target's `AGENT_OS_SOURCE` line, in-place value (synced, not reset to `REPLACE_BASICSOURCE`).
- Target's date-stamped filenames, custom skills (none expected in thin-client, but if added, keep), and any `.work/` content the user/session-control produced.
- Target's git history, `.gitignore`, app code — all untouched.

---

## I3 — status (read-only)

Shell: `bash <source>/scripts/deploy-basic.sh --status [target-path]` (bare `status` ≡ `--status`)

The `.cursorrules` checks are delegated to `scripts/cursorrules-verify.sh` (single source of truth, also runs as post-deploy verification after every bootstrap/update). Reports:

| Check | Output |
|-------|--------|
| `.cursorrules` present | pass / missing |
| `AGENT_OS_SOURCE` value + reachable | value + `test -d` result (FAIL when unfilled or unreachable) |
| Gate-table script paths baked | ok / FAIL when literal `.ai/scripts/` remains or a baked prefix is stale |
| Sister-framework cells (`.ai.ui/.ai.biz/.ai.soc`) | reachable / unfilled-token (warn when installed) / STALE (FAIL) |
| Source-resolution section present | pass / missing (warn → merge candidate) |
| `.work/` present | pass / missing |
| Local `.ai/skills/` exists (fat-client leak) | no (good, thin) / yes (warn — mixed) |
| `REPLACE:` tokens remaining in `.cursorrules` | count (excludes `AGENT_OS_SOURCE` which is filled) |
| **`opencode.json` present** | pass / missing |
| **`opencode.json` path drift** | `skills.paths[0]` vs expected `$AGENT_OS_SOURCE/skills` → **ok** or **STALE** |

Exit code: non-zero when any `[FAIL]` finding remains (stale source, unbaked paths, stale sister cell, missing `.cursorrules`). Repair verb: `@deploy-basic update` (runs `cursorrules-verify.sh --fix`).

---

## Completion

| # | Check | Result |
|---|-------|--------|
| 1 | Source `templates/cursorrules.template` readable | pass |
| 2 | Target `.cursorrules` exists with valid `AGENT_OS_SOURCE` (resolves to a dir) | |
| 3 | Source-resolution section present in target `.cursorrules` | |
| 4 | `.work/` skeleton present (HANDOFF, NEXT, UNKNOWNS at minimum); empty `.work/standards/` + `.work/docs/integration/` present | |
| 5 | **No local `.ai/` directory created** (thin-client invariant) | |
| 6 | No-overwrite honored (existing target files preserved; `--force` only when explicitly requested) | |
| 7 | `update`: source pointer re-synced if stale; **opencode `--sync-paths`** run; merge candidate list produced; no wholesale replaces | |
| 8 | Fat-client leak checked (no unexpected local `.ai/skills/`) | |
| 9 | User informed that skills load from `$AGENT_OS_SOURCE` at runtime + next steps | |

## Next commands (in target project)

```text
# Verify the source is reachable from the target's perspective:
test -d "$(grep -oE 'AGENT_OS_SOURCE=[^ ]*' .cursorrules | head -1 | cut -d= -f2-)"

# Fill remaining REPLACE tokens in .cursorrules (NOT AGENT_OS_SOURCE — deploy-basic set it):
#   rg 'REPLACE:' .cursorrules

# First skill invocation — loads from source:
@session-control start
```

---

## Coding-agent config (tool-agnostic)

Thin-client always writes `.cursorrules` with `AGENT_OS_SOURCE`. **opencode** users also need `opencode.json` at the repo root (skill paths point at `$AGENT_OS_SOURCE`, not a local `.ai/`):

```bash
# After deploy-basic (from target repo root) — create if missing:
REPO_ROOT="$(pwd)" bash "$(grep -oE 'AGENT_OS_SOURCE=[^ ]*' .cursorrules | cut -d= -f2-)/scripts/install-opencode-config.sh"

# After source moved — surgical path sync (preserves mcp + custom entries):
REPO_ROOT="$(pwd)" AI_SOURCE="$(grep AGENT_OS_SOURCE= .cursorrules | cut -d= -f2-)" \
  OLD_SOURCE=/old/path/.ai bash "$AI_SOURCE/scripts/install-opencode-config.sh" --sync-paths

# Full regenerate (destructive — drops custom mcp/instructions):
REPO_ROOT="$(pwd)" AI_SOURCE=... bash "$AI_SOURCE/scripts/install-opencode-config.sh" --force

# Check path drift:
bash "$AI_SOURCE/scripts/deploy-basic.sh" --status .
```

Cursor / Claude Code / Codex: `.cursorrules` is sufficient for skills; use `@project-query-setup register-mcp` for MCP. See `deploy-files` skill § Coding-agent config for the full matrix.

---

## Critical interactions

| When | Ask / do |
|------|----------|
| Invoked from target with no source pointer yet (greenfield, no `.cursorrules`) | The skill itself can't be loaded in thin-client mode before bootstrap. Tell the user to run the shell directly: `bash /abs/path/to/source/scripts/deploy-basic.sh .` — chicken-and-egg escape (see `.cursorrules` § Source resolution). |
| Bootstrap target already has `.ai/skills/` (fat-client) | Warn; ask: convert to thin (delete local `.ai/`)?, keep mixed (skills resolve local-first per fat-client rule — unexpected)?, or abort? Do not silently leave a mixed state. |
| `update` finds `.cursorrules` with no `AGENT_OS_SOURCE` line | Fat-client template detected → flag as merge candidate; agent appends the Source-resolution section with current source value. |
| Source moved since last bootstrap | `update` re-syncs `AGENT_OS_SOURCE` in `.cursorrules` **and** runs `install-opencode-config.sh --sync-paths`. Run `@deploy-basic status` to confirm opencode paths match. If still stale → merge candidate or `--force` (operator opt-in). |

---

## Anti-patterns

- Copying `skills/`/`standards/`/`concepts/` into the target (that defeats thin-client; use `@deploy-files` instead).
- Wholesale-replacing `.cursorrules` or `.work/HANDOFF.md` on `update`.
- Resetting `AGENT_OS_SOURCE` to `REPLACE_BASICSOURCE` instead of the resolved path.
- Running `@deploy-basic` and expecting skills to work offline — thin-client requires the source path to remain reachable.
- Failing to verify `$AGENT_OS_SOURCE` is readable before claiming bootstrap complete.
- Invoking `@deploy-basic -` from the source dir **without** a target path — the shell aborts; the agent must prompt for the target rather than guessing or defaulting to the source's own cwd.
- Using `deploy-basic` to "upgrade" a fat-client repo without first removing the local `.ai/` (creates a mixed state; skills resolve fat-client first).
- Running `install-opencode-config.sh --force` when `--sync-paths` would suffice (destroys custom MCP / instructions).