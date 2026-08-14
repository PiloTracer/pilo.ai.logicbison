# HANDOFF - session boundary

> **This is a template file.** In your adopter repo it is rewritten by **`@session-control start`** / **`@session-control close`** every session. In this framework repo it stays as a demo skeleton so pointer links resolve.

## Session status

**Closed:** 2026-08-14 — session-control commit scope is now repo-mode dependent (whole repo in framework source; `.work/` + general root files in consumers), synced across skill docs, rules, templates, and CHANGELOG; all verifiers pass; committed and pushed. See `## What this cycle produced` for details.

**Updated:** 2026-08-14

Treat the next chat as a **new session**: do not assume unwritten goals from prior threads unless they appear here or in linked artifacts.

**Repository state:** Agent OS framework repo (self-hosted). Latest tag `v0.6.0`; `[Unreleased]` holds deploy-arg-parsing + cursorrules-verify work and the session-control scope change. All skills in `ANCHOR_CLEAN` set. `framework-verify` + `skill-functional-verify` + `touch-scope-verify` exit 0 (verified 2026-08-14).

**Recommended pick-up file:** `.work/plans/NEXT.md`

**Lost or new?** Read `START_HERE.md` (from repo root).

---

## Fresh start - what the next session should do first

1. Run **`@session-control start`** (or follow the manual list in `session-control` skill).
2. Read **`.cursorrules`**.
3. Read **P0 initial scope** when present: `.work/plans/foundation/*-01-*-initial-scope.md`.
4. Read **this file** through §Fresh start, then §Open owner actions.
5. Read `.work/plans/NEXT.md`.
6. Read `.work/plans/ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md`.

End with **`@session-control close`** (add `commit` / `commit push` only when requested). For mid-session checkpoints use **`@session-control commit`** or **`@session-control commit push`** (no close).

### Conditional reads (customize per project)

| If the task touches… | Read first |
|----------------------|------------|
| Product scope / foundation | `.work/plans/foundation/*-01-*.md` … `*-04-*.md` |
| Any code or new feature | `.work/standards/*CONVENTIONS*`, `*FEATURE_STANDARD*` |
| External integration | `*-02-*.md`, `.work/docs/integration/MANIFEST.txt` (if any) |
| Security | `.work/standards/*threat-model*` |
| Stack / topology | `REPLACE:TECH_STACK_DOC` |
| Master plan / milestones | `.work/plans/full/*-full-plan.md` |
| High-risk feature | Relevant `.work/features/<slug>/*-SPEC.md` |
| Unmapped app surfaces / registry gaps | `@plan-verify coverage` |

---

## Open owner actions

| # | Action | Blocks | Owner |
|---|--------|--------|-------|
| 1 | Approve remediation of already-bootstrapped consumers (`tools-rfp`, `tools-project`) for the `standards`/`docs/integration` path fix — see NEXT.md P5 | Cleanup of stray `.ai/standards/`+`.ai/docs/integration/` in those repos | Owner |

---

## What this cycle produced (audit history - skim last session only)

| Date | Session | Artifacts |
|------|---------|-----------|
| 2026-08-14 | session-control repo-mode commit scope | Owner directive: session commits apply to the **whole repo** in the Agent OS framework source repo, and to `.work/` + root-level `PROCESS_ROUTER.md`/`DOCS_TECH_STACK.md`/`CHANGELOG.md` (if present) in consumer repos. Mode detection: framework source ⇔ root contains `templates/cursorrules.template` + `skills/session-control/skill.md`. Updated `skills/session-control/skill.md` (frontmatter, hard rules, parse table, commit-scope section, critical interactions, anti-patterns, project layout), `skills/session-control/reference.md` (default-scope note, examples, git-verbs table, edge cases, wrong-prompts, C4b scope steps, post-commit verification, both checklists, critical interactions), `.cursorrules` + `templates/cursorrules.template` (git rule + skills row; template keeps consumer wording), `skills/README.md` row, `CHANGELOG.md` [Unreleased] (supersedes the 0.6.0 `.work/`-only note). Secrets/`tmp/`/protected-file exclusions unchanged in both modes; `commit scoped` unchanged; `push` ships the whole branch. Scope declared in `.work/touch-scope`. `framework-verify` + `skill-functional-verify` + `touch-scope-verify` exit 0. Consumer-side behavior not live-smoke-tested this session (doc-level change). |
| 2026-08-12 | plan-foundation evidence-based stack grills (committed as `70dc9a1` without a booked session close; recorded here retroactively) | `skills/plan-foundation/reference.md` (+95 lines: stack grills), `skills/plan-foundation/skill.md`, MOD-06 output `.work/analysis/20260812-mod06-plan-foundation-stack-grill-gaps.md`, `.work/touch-scope` |
| 2026-07-06 | Full framework audit + gap remediation | Audited 100% of framework codebase; fixed `framework-verify` false positives by excluding vendored paths from markdown link scanner; completed `.cursorrules` placeholder map (`SERVICE_API`, `SERVICE_DB`, `FRONTEND_ROOT`, `FRONTEND_CONFIG_PATHS`, `STACK_SUFFIX_VAR`, `SCRIPTS_DIR`, `APP_ENTRYPOINT`); synced `{DOCS_ROOT}` into `templates/cursorrules.template`; added `.work/reports/` to bootstrap scaffold and updated `templates/README.md`; created `.work/PROTECTED_SURFACES.json`; fixed anchors/terminology in `plan-foundation`/`plan-master` skills; corrected stale `setup-target.sh` refs in `CHANGELOG.md`, MOD-07 refs in `concept-run`/`ai-director`, workflow index numbering, `START_HERE.md` heading, and `x-director` dangling `.ai.soc` cross-reference; normalized script executable bits; declared scope in `.work/touch-scope`. Generated `.work/reports/full-audit-report.md` and MOD-06 output `.work/analysis/20260706-mod06-full-audit.md`. `framework-verify` + `skill-functional-verify` + `touch-scope-verify` exit 0. |
| 2026-07-06 | Master-plan-standard fix from external smoke-test feedback | Validated 7 reported issues against repo evidence (1 confirmed framework bug, 1 confirmed enforcement gap, 1 partial, 4 not framework gaps — see report in session transcript). **Confirmed root cause:** `templates/work/plans/full/YYYYMMDD-full-plan.md.template` shipped only 11/25 mandatory `MASTER_PLAN_STANDARD.md` H2 sections (§9–§18, §22–§25 missing) — fixed to all 25 in order. **New:** `scripts/master-plan-verify.sh` (25-section completeness/ordering + Approved↔integrity consistency check), wired into `@plan-verify master` M3 and `framework-verify.sh` self-test (3 new cases). `skills/plan-foundation/skill.md` GF0 now warns on placeholder `.work/touch-scope`. `standards/20260519-MASTER_PLAN_STANDARD.md` §References links the new script. `CHANGELOG.md` [Unreleased]. Declined: an "express/smoke profile" mode (already covered by existing anti-pattern rules — mechanizing further needs a dedicated design pass, not a drive-by fix) and forcing `git init` in `project-bootstrap` (opinionated behavior change without clear consent model). `framework-verify` + `skill-functional-verify` + `touch-scope-verify` exit 0. MOD-06 output: `.work/analysis/20260706-mod06-master-plan-standard-fix.md`. |
| 2026-07-05 | `.ai/standards`/`.ai/docs/integration` write-target fix | `templates/cursorrules.template`, `templates/bootstrap.sh`, `templates/README.md`, `templates/DOCS_TECH_STACK.md.template`, `templates/work/context/HANDOFF.md.template`, `templates/work/plans/foundation/*-02-*.template` + `*-04-*.template`, `scripts/setup-target.sh`, `standards/20260517-{CONVENTIONS,DIRECTORY_MAP}.md`, `README.md`, `features/README.md`, `docs/integration/{README,MANIFEST.template.txt}`, `docs/adoption/minimal-adoption.md`, `docs/guides/workflows/{README,20260518-tutorial-path-bootstrap,20260518-guide-boundary-map-howto}.md`, `.gitignore`, and 15 skill docs (`plan-foundation/reference`, `project-bootstrap`, `code-verify`, `code-implementation` ×2, `session-control/reference`, `plan-verify` ×2, `plan-repair` ×2, `plan-master` ×2, `feature-spec` ×2, `db-migration`, `code-repair`, `process-router/reference`) — moved project-owned generated standards + vendor integration mirrors from `.ai/`-prefixed paths to project-root `standards/`+`docs/integration/` (sibling of `.work/`); kept the legitimate framework-wide `.ai/standards/MASTER_PLAN_STANDARD.md` contract untouched; `bootstrap.sh`/`setup-target.sh` now scaffold both dirs empty; `framework-verify`/`skill-functional-verify` exit 0 |
| 2026-07-05 | AIOS-1 plan-foundation fix + skill.md repair + verify-tooling hardening | `skills/plan-foundation/skill.md` (restored `## Probe protocol`/`## Greenfield protocol` headings, closed unclosed fence, removed leaked template heading + ~15 lines duplicated/orphaned text, fixed dangling table, corrected same-file anchor hyphen counts + cross-file `reference.md#` prefixes); `skills/plan-foundation/reference.md` (minor alignment); `scripts/skill-functional-verify.py` (`strict_slug`, `strip_fences`, `same_file_issues` — detects unclosed fences + broken same-file anchors; `ANCHOR_CLEAN` set); `.work/plans/UNKNOWNS.md` (U1 cross-skill anchor debt, U2 P0 registry-ordering ambiguity); `.work/plans/NEXT.md` (P2, P3) |
| 2026-07-05 | AIOS-1 v0.5.0 rules token-optimization | `.cursorrules` (−42%), `templates/cursorrules.template` (−41%); MOD-06→MOD-07 template fix; `concept-run` desc fix (both files); `CHANGELOG.md` [0.5.0]; tag `v0.5.0`; GitHub release published; framework-verify + skill-functional-verify exit 0 |
| 2026-07-04 | AIOS-1 change-safety layer | `blast-radius-check.sh`, `touch-scope-verify.sh`, `mod06-output-check.sh`, `golden-deploy-verify.sh`, `PROTECTED_SURFACES.json`, `hooks/pre-commit`, skills (code-verify, code-implementation, code-repair), `.cursorrules` §Change safety, `DOCS_TECH_STACK.md` dogfood, `CONTRIBUTING.md`, `CHANGELOG.md`, consumer templates (`touch-scope`, `PROTECTED_SURFACES`); framework-verify exit 0 |
| 2026-07-02 | deploy + opencode verification + README customization | `install-opencode-config.sh`, `deploy-basic.sh`, `deploy-files.sh`, `framework-verify.sh`, deploy/opencode skills, `CHANGELOG.md`, `.quick/deploy-to-project.md`; live smoke tools-project + test-test clone; commit `17658f4`; README Customization section |
| 2026-07-01 | deploy-basic + session-control context + deploy-files merge | `skills/deploy-basic/skill.md`, `scripts/deploy-basic.sh`, `skills/deploy-files/skill.md`, `skills/session-control/skill.md`, `skills/session-control/reference.md`, `.cursorrules`, `templates/cursorrules.template`, `templates/bootstrap.sh`, `skills/README.md`, `SKILL_DEPENDENCIES.md`, `.quick/deploy-to-project.md`, `.quick/session-lifecycle.md`, `PROCESS_ROUTER.md`, `START_HERE.md` — new deploy-basic thin-client bootstrap skill; deploy-files enhanced with in-place no-overwrite bootstrap + rules-aware merge; session-control context mode (read-only full context + uncommitted-aware dirty-tree); all registries and templates updated |
| 2026-06-30 | .ai.soc integration + x-director sole router | `.cursorrules`, `templates/cursorrules.template`, `x-director/skill.md`, `ai-director/skill.md`, `ai-director/reference.md`, `SKILL_DEPENDENCIES.md`, `.quick/directors.md`, `skills/README.md`, `README.md`, `PROCESS_ROUTER.md`, `context/README.md` — .ai.soc added to frameworks registry, auto-discovery, bucket tables; ai-director refactored to channel non-.ai to x-director; x-director named sole cross-framework routing authority |
| 2026-06-30 | session-control local task registry | `skills/session-control/skill.md` — replaced network-dependent curl call with local `.github/task-registry.json` file read for S4c, M4, C4 ref extraction |
| 2026-06-25 | prepare-commit-msg hook + cursorrules refs | `hooks/prepare-commit-msg` git hook; Task Refs section in cursorrules.template; human-readable commit rule; clarified `auto_prefix_enabled` docs |
| 2026-06-25 | github registry polish | `API_BASE_URL` env var, simplified S4c, consistent M4/C4 extraction wording |
| 2026-06-25 | session-control commit verb + task refs | `@session-control commit`/`commit push` standalone verb; auto task-ref extraction in commit messages (HANDOFF/branch/prior commit); optional GitHub task registry discovery; updated skill.md, reference.md, .cursorrules/template, SKILL_DEPENDENCIES.md, quick refs |
| 2026-06-23 | deploy-files to tools-project | `@deploy-files copy - /mnt/work/Projects/tools-project` — 153 files re-copied to `tools-project/.ai/` (git-ignored content excluded) |
| 2026-06-23 | director free-text intake | `skills/ai-director/skill.md` + `skills/x-director/skill.md` gained explicit Free-text intake contracts (capture → load → classify → channel → record); `.cursorrules`, `START_HERE.md`, `PROCESS_ROUTER.md`, `README.md`, `context/README.md` now route free-text requests to `@ai-director` / `@x-director`; self-hosted path references corrected throughout `.cursorrules` |
| 2026-06-01 | .work/ dir structure | `.work/analysis/`, `.work/scripts/` + READMEs; `.work/README.md`, `DIRECTORY_MAP`, `bootstrap.sh` updated |
| 2026-06-01 | gate-verify integration | `gate-verify.sh` in CI + release; CHANGELOG, CONTRIBUTING updated; 4 broken links fixed |
| 2026-05-27 | Coverage/registry parity | `plan-verify` coverage mode; `plan-repair` from coverage; FEATURE_STANDARD §14; DIRECTORY_MAP gate; templates/work/reports |

---

## Explicit unknowns (promoted from UNKNOWNS)

| ID | Summary | Blocks | Owner | Status |
|----|---------|--------|-------|--------|
| U1 | 18 pre-existing broken same-file `#anchor` links across 8 skills — **repaired 2026-07-06**; all 9 trimmed skills now in `ANCHOR_CLEAN` hard-fail set | No — resolved | owner | Closed |
| U2 | Greenfield P0 registry ordering — **fixed 2026-07-06** (registries created greenfield step 3, before `p0-probe` step 4) | No — resolved | owner | Closed |

---

## Cross-LLM verification

- **Triggered:** no
- **Result:** -
- **Notes:** -
