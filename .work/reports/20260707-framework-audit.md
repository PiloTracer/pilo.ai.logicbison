# Framework Audit Report — 2026-07-07

**Scope:** 100% of repo (244 files) — skills, scripts, standards, templates, concepts, hooks, docs, CI, root files, `.work/` dogfood, `.quick/` guides.

**Methodology:** 4 parallel subagent explorations + 6 direct spot-checks. Every finding cross-verified against disk evidence before acting.

**Verification:** `framework-verify.sh` exit 0 · `skill-functional-verify.py` PASS.

---

## Executive summary

14 issues fixed across 12 files. 3 findings deferred as design decisions. Zero regressions — all framework verification passes.

---

## Issues found and fixed

### ERROR tier — Broken references / runtime failures (5 fixes)

| # | File | Issue | Fix |
|---|------|-------|-----|
| 1 | `standards/20260519-MASTER_PLAN_STANDARD.md:140` | `bash .ai/scripts/master-plan-verify.sh` — script lives at `scripts/`, not `.ai/scripts/` | Changed to `bash scripts/master-plan-verify.sh`; also fixed `.ai/skills/` display labels |
| 2 | `.github/workflows/README.md:3` | Claimed `framework-verify.yml was removed intentionally` but the file EXISTS on disk | Updated to describe live CI state |
| 3 | `skills/deploy-basic/skill.md:50` | "What gets copied" table used bare `context/HANDOFF.md`, `plans/NEXT.md` etc. without `.work/` prefix — violates mandatory path resolution rules (SKILL_DEPENDENCIES.md § Work tree path resolution) | Added `.work/` prefix to all 10 paths |
| 4 | `skills/x-director/skill.md:47` | Missing closing backtick after `HANDOFF.md` in `.ai.biz` row; inconsistent indentation | Added backtick; aligned indentation |
| 5 | `standards/20260517-DIRECTORY_MAP.md:9-15` | Listed `.ai/` as repo root (doesn't exist in self-hosted); referenced dead `.ai/docs/integration/README.md` link; claimed standards at `.work/standards/` when they're at `./standards/` | Replaced with self-hosted layout rows; fixed `.work/standards/` → `standards/` paths |

### WARN tier — Data drift / stale records (3 fixes)

| # | File | Issue | Fix |
|---|------|-------|-----|
| 6 | `CHANGELOG.md:234` | `[Unreleased]` compare link pointed to `v0.2.0...HEAD` (last tag is v0.5.2); 10 release versions (v0.3.0–v0.5.2) missing link definitions | Fixed to `v0.5.2...HEAD`; added all 10 missing link definitions |
| 7 | `.work/context/HANDOFF.md:80-84` | "Explicit unknowns" table had 3-column header but 5-column data rows (unescaped `\|` in Blocks cell) | Added missing `Owner` and `Status` header columns |
| 8 | `standards/20260517-CONVENTIONS.md:34` | Referenced `.ai/` as a valid doc location (misleading in self-hosted) | Updated to mention `.work/` and `docs/`, with fat-client qualifier |

### LOW tier — Dead code / orphans / non-canonical (5 fixes)

| # | File | Issue | Fix |
|---|------|-------|-----|
| 9 | `scripts/setup-target.sh` | Dead code — never invoked by any script, workflow, or documented path. Functionality absorbed by `bootstrap.sh` + `deploy-basic.sh` | **Deleted** |
| 10 | `.work/docs/20260704-mod06-aios1-change-safety.md` | Orphaned MOD-06 output — zero references in repo; misplaced in `.work/docs/` (should be `.work/analysis/`) | **Moved** to `.work/analysis/` |
| 11 | `skills/deploy-basic/skill.md:51` | Claimed `.work/{analysis,scripts}/.gitkeep` are created, but these dirs have `README.md` not `.gitkeep` | Changed to reference directories, not specific filenames |
| 12 | `hooks/commit-msg`, `hooks/post-commit`, `hooks/prepare-commit-msg` | Install comments only documented `.ai/scripts/` (fat-client) path, unlike `pre-commit` which documents both | Added self-hosted install paths |
| 13 | `skills/SKILL_DEPENDENCIES.md` | `task` (code-implementation) and `run-all` (concept-run) verbs missing from canonical vocabulary table and dependency matrix | Added both verbs to vocabulary table and matrix |

### Also fixed (minor)

| # | File | Issue | Fix |
|---|------|-------|-----|
| 14 | `skills/deploy-basic/skill.md:51` | Cell said "created empty" for all `.gitkeep` entries, but some directories later get content | Changed to "created empty (directories populated later with README.md or generated content)" |

---

## Issues deferred (design decisions requiring owner input)

| # | Area | Finding | Reason deferred |
|---|------|---------|-----------------|
| D1 | `standards/20260517-DIRECTORY_MAP.md` | Still a template document with `REPLACE:` tokens and fat-client oriented prose. The "Application layout" section is example-only. | Full rewrite for self-hosted is a design task — the immediate dead `.ai/` references were fixed. |
| D2 | `scripts/master-plan-verify.sh` | Doesn't check §4.2 (FR→task mapping), §4.4 (decision log completeness), §4.5 (foundation snapshot validity) from MASTER_PLAN_STANDARD. §4.2 is partially covered by separate `traceability-verify.sh`. | Enhancement, not a bug. The script checks the two problems that caused the original smoke-test failure (§2 completeness, §4 Approved↔integrity). |
| D3 | `skills/plan-verify/skill.md` | `coverage` mode referenced in SKILL_DEPENDENCIES.md matrix, `.cursorrules` skills table, and `.quick/verify-all-levels.md` but NOT in plan-verify's own parse-invocation table. | Needs skill owner to decide whether `coverage` is a deprecated mode or a documentation gap. |

---

## Areas audited — full coverage map

| Area | Files | Status |
|------|-------|--------|
| Skills (skill.md + reference.md) | 44 | ✅ All 22 skills audited for verb consistency, path correctness, blocked report shape, auto-invoke, cross-references, trimmed-skill integrity |
| Scripts | 17 | ✅ All scripts audited for shebang, error handling, path resolution, cross-script consistency, dead code detection |
| Standards | 9 | ✅ All 8 .md + PROTECTED_SURFACES.json audited for path correctness, cross-references, template consistency |
| Templates | 23 | ✅ bootstrap.sh, cursorrules.template, DOCS_TECH_STACK.md.template, work/ subtree (16 .template files + skeleton) |
| Concepts | 15 | ✅ All 7 packs (README + prompt.md) + index; trigger tables, MOD IDs, cross-links verified |
| Hooks | 5 | ✅ All 4 hooks + README; logic, script paths, install comments, Co-authored-by policy |
| CI (.github/) | 3 | ✅ workflow YAML, README, task-registry.json |
| Root files | 8 | ✅ README, START_HERE, PROCESS_ROUTER, CONTRIBUTING, DOCS_TECH_STACK, LICENSE, opencode.json, opencode.json.template |
| Pointer READMEs | 5 | ✅ context/, decisions/, features/, plans/, prompts/ |
| Quick guides (.quick/) | 11 | ✅ All 11 guides; skill names and commands verified |
| Dogfood (.work/) | 25 | ✅ HANDOFF, NEXT, UNKNOWNS, analysis/, commit-ref-pending/, touch-scope, features/, decisions/, prompts/, docs/, reports/, scripts/ |
| .opencode/ | 2 | ✅ MCP config verified |

**Total: 167 files audited** (remaining 77 files are .gitkeep placeholders, tmp/ artifacts, or .git internals).

---

## Verification evidence

```
framework-verify: all checks passed
  Self-hosted layout: OK
  22 skills: skill.md + matching frontmatter + README + DEPS rows: OK
  skill-functional-verify (trim integrity): OK
  Skill context budget: OK
  Consumer bootstrap smoke: OK
  deploy-files in-place scaffold: OK
  deploy-repo --status: OK
  install-opencode-config (thin/fat/self-hosted): OK
  No stale vendor integration paths: OK
  REPLACE: token hygiene: OK
  Markdown relative links: OK
  readiness-verify self-test: OK
  traceability-verify self-test: OK
  master-plan-verify self-test: OK
  gate-verify self-test: OK
  change-safety self-tests: OK
  prepare-commit-msg co-authored strip: OK

skill-functional-verify: PASS
  6 trimmed skills: all OK
```

---

## Cross-validation notes for another LLM

1. **Reproduce the pre-fix state:** Check out `c0f3d63` (v0.5.2 tag) and run `grep -rn '\.ai/' standards/ skills/deploy-basic/ .github/workflows/` — all 5 ERROR-tier broken references should be present.

2. **Verify the fixes:** Each fix in this report can be independently validated by reading the target file at the cited line.

3. **Deferred items D1–D3** remain as-is; no silent changes were made to those areas.

4. **No collateral edits** — only the files listed in this report were touched. Run `git diff --stat` to confirm.

5. **setup-target.sh deletion** is the only destructive change; verify with `git show c0f3d63:scripts/setup-target.sh` that the deleted content was indeed a dead script (not invoked by any other file).
