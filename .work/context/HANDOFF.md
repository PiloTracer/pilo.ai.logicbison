# HANDOFF - session boundary

> **This is a template file.** In your adopter repo it is rewritten by **`@session-control start`** / **`@session-control close`** every session. In this framework repo it stays as a demo skeleton so pointer links resolve.

## Session status

**Closed:** 2026-07-05 — v0.5.0 released: token-optimized `.cursorrules` + template (−42% / −41%), MOD-07 drift fixed; committed, tagged, pushed, GitHub release published.

**Updated:** 2026-07-05

Treat the next chat as a **new session**: do not assume unwritten goals from prior threads unless they appear here or in linked artifacts.

**Repository state:** Agent OS framework repo (self-hosted). `main` synced with `origin/main`. Latest: v0.5.0 — token-optimized always-applied rules + adopter template; all normative rules preserved (31/31 verified); `framework-verify` + `skill-functional-verify` exit 0.

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
| Any code or new feature | `.ai/standards/*CONVENTIONS*`, `*FEATURE_STANDARD*` |
| External integration | `*-02-*.md`, `.ai/docs/integration/MANIFEST.txt` (if any) |
| Security | `.ai/standards/*threat-model*` |
| Stack / topology | `REPLACE:TECH_STACK_DOC` |
| Master plan / milestones | `.work/plans/full/*-full-plan.md` |
| High-risk feature | Relevant `.work/features/<slug>/*-SPEC.md` |
| Unmapped app surfaces / registry gaps | `@plan-verify coverage` |

---

## Open owner actions

| # | Action | Blocks | Owner |
|---|--------|--------|-------|
| - | (none) | | |

---

## What this cycle produced (audit history - skim last session only)

| Date | Session | Artifacts |
|------|---------|-----------|
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

| ID | Summary | Blocks |
|----|---------|--------|
| - | | |

---

## Cross-LLM verification

- **Triggered:** no
- **Result:** -
- **Notes:** -
