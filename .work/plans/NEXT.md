# NEXT - planning backlog

> **This is a template file.** In your adopter repo it is maintained by **`@code-implementation`** (the `## Current iteration` block) and **`@session-control close`** (the `## Recommended next` row). In this framework repo it stays as a demo skeleton.

**Updated:** 2026-07-05

---

## Done

| Item | Artifact |
|------|----------|
| Agent OS bootstrap | `.work/` skeleton, `.cursorrules` from template |
| Standalone commit verb + task-ref extraction + hook | `@session-control commit`/`commit push`; auto ref from HANDOFF/branch/prior commit; GitHub task registry discovery; `API_BASE_URL`; `prepare-commit-msg` hook; cursorrules Task Refs + readability rules; deployed to tools-project |
| Code-to-registry coverage | `@plan-verify coverage`, `@plan-repair repair - from coverage`, FEATURE_STANDARD §14, reports template |
| gate-verify integration | `gate-verify.sh` in CI, release preflight; CHANGELOG, CONTRIBUTING; 4 broken links fixed |
| .work/ dir structure | `.work/analysis/` and `.work/scripts/` + READMEs; `.work/README.md`, `DIRECTORY_MAP`, `bootstrap.sh` |
| .ai.soc integration + x-director sole router | `.cursorrules`, `templates/cursorrules.template`, `x-director/skill.md`, `ai-director/skill.md`, `ai-director/reference.md`, `SKILL_DEPENDENCIES.md`, `.quick/directors.md`, `skills/README.md`, `README.md`, `PROCESS_ROUTER.md`, `context/README.md` |
| session-control local task registry | `skills/session-control/skill.md` — replaced network curl call with local `.github/task-registry.json` file read |
| deploy-basic + session-control context + deploy-files merge | `skills/deploy-basic/`, `scripts/deploy-basic.sh`, `skills/deploy-files/skill.md`, `skills/session-control/skill.md`, `skills/session-control/reference.md`, `.cursorrules`, `templates/`, `skills/README.md`, `SKILL_DEPENDENCIES.md`, `.quick/`, `PROCESS_ROUTER.md`, `START_HERE.md` — new deploy-basic thin-client bootstrap skill; deploy-files in-place no-overwrite bootstrap + rules-aware merge; session-control context mode with uncommitted-aware dirty-tree summary; registries, templates, docs updated |
| deploy + opencode verification (2026-07-02) | `install-opencode-config.sh`, deploy-basic `--status`/`--sync-paths`, deploy-files opencode on `--update`, `framework-verify` deploy smoke (thin + fat-client), README platform note, `.quick/deploy-to-project.md`; tools-project opencode repaired live; commit `17658f4` |
| README customization note (2026-07-02) | README §Customization — adopters may adapt skills, rules, and project memory via their coding agent |
| AIOS-1 change-safety layer (2026-07-04) | `blast-radius-check.sh`, `touch-scope-verify.sh`, `mod06-output-check.sh`, `golden-deploy-verify.sh`, `PROTECTED_SURFACES.json`, pre-commit hook, skills/docs/CI wiring; tag `v0.4.4` |
| v0.5.0 rules token-optimization (2026-07-05) | `.cursorrules` −42%, `templates/cursorrules.template` −41% (all rules preserved, 31/31 verified); MOD-06→MOD-07 template fix; `CHANGELOG.md` [0.5.0]; tag `v0.5.0` + GitHub release |
| AIOS-1 plan-foundation question-order fix + skill.md repair (2026-07-05) | Confirmed greenfield question order (name → p0-intent → p0-probe → integrations/stack); repaired pre-existing `skill.md` structural corruption (unclosed fence, missing headings, duplicated/orphaned text, dangling table, same-file anchor mismatches) dating to the v0.4.3 skill-trim; `plan-foundation` now in `ANCHOR_CLEAN` set; `skill-functional-verify.py` hardened with same-file anchor + fence-balance checks |
| Thin-client script-path baking (2026-07-05) | `deploy-basic.sh` now bakes resolved `$AGENT_OS_SOURCE/scripts/...` absolute paths into a target's `.cursorrules` at bootstrap/`update` time (Change-safety gate table + Co-authored-by hook install line), instead of leaving literal `.ai/scripts/...` text; `templates/cursorrules.template` wording clarified; validated live against `tools-rfp` |
| Fix `.ai/standards`/`.ai/docs/integration` write-target bug (2026-07-05) | Root cause: `templates/cursorrules.template`, `templates/bootstrap.sh`, `templates/work/context/HANDOFF.md.template`, `templates/work/plans/foundation/*-02-*.template` + `*-04-*.template`, `scripts/setup-target.sh`, and ~15 skill docs (`plan-foundation`, `project-bootstrap`, `code-verify`, `code-implementation`, `code-repair`, `session-control`, `plan-verify`, `plan-repair`, `plan-master`, `feature-spec`, `db-migration`, `process-router`) instructed writing/reading project-owned deliverables (CONVENTIONS, FEATURE_STANDARD, DIRECTORY_MAP, threat-model, data-classification, observability-spec, api-style-guide, `docs/integration/MANIFEST.txt`) under a local `.ai/` prefix — confirmed live in `tools-rfp` (stray `.ai/standards/` + `.ai/docs/integration/` created there). Fixed to project-root `standards/` + `docs/integration/` (sibling of `.work/`, never under `.ai/`, in both fat- and thin-client modes) everywhere except the legitimate framework-wide `.ai/standards/MASTER_PLAN_STANDARD.md` contract. `bootstrap.sh`/`setup-target.sh` now scaffold empty project-root `standards/`+`docs/integration/`. `framework-verify` + `skill-functional-verify` exit 0; `touch-scope-verify` pass; `blast-radius-check` flags expected high risk (protected deploy scripts/templates touched, pre-approved by owner in-message). Also smoke-tested `deploy-basic`, `deploy-files` (outbound + in-place) live in scratch dirs to confirm all three still bootstrap correctly and consistently post-fix (project-root `standards/`+`docs/integration/` scaffold empty; fat-client `.ai/standards/` vendored copy unaffected); fixed two resulting doc gaps in `skills/deploy-basic/skill.md` and `skills/deploy-files/skill.md` (What-gets-copied / scaffold tables + an ambiguous update-merge row). `deploy-repo` unaffected (git-native, no `.ai/`-prefix logic). **Scope: `.ai` framework repo only — `tools-rfp`/`tools-project` still carry the old bug until they re-run `@deploy-basic update` / `@deploy-files update` / `@project-bootstrap` against this fixed source (see P1/P5).** |

---

## Blocked on owner

| # | Item | Notes |
|---|------|-------|
| - | (none) | |

---

## Recommended next

| Priority | Item | Notes |
|----------|------|-------|
| **P1** | Deploy v0.5.0 + AIOS-1 fix + standards/docs path fix to tools-project | `@deploy-files copy - /path` or `@deploy-basic update` — propagates token-optimized rules, the repaired `plan-foundation/skill.md`, the thin-client script-path baking fix, and the `standards`/`docs/integration` project-root path fix to adopters. Resolve the actual source path dynamically from the current `.ai` repo location at invocation time (`pwd`/git-root), never from a memorized/hardcoded value — `deploy-files.sh`/`deploy-basic.sh` already derive `AI_ROOT` from the invoked script path, so pass the script's real current path. |
| **P2** | Cross-skill anchor-hygiene cleanup | 18 pre-existing broken same-file `#anchor` links across 8 skills, surfaced as `DEBT` by the now-enhanced `skill-functional-verify.py` — see `UNKNOWNS.md` U1. `plan-foundation` already fixed (in `ANCHOR_CLEAN` set); repeat the same repair pattern for the rest, then promote them into `ANCHOR_CLEAN` |
| **P3** | Clarify greenfield P0 registry-creation ordering | `UNKNOWNS.md` U2 — `p0-probe` needs `ASSUMPTIONS`/`RISK_REGISTRY`/`UNKNOWNS` to exist before it can record into them; current step order only guarantees this "by GATE p0" |
| **P4** | Live greenfield walkthrough | Run `@plan-foundation greenfield` end-to-end on a scratch/test project now that `skill.md` is structurally clean, to confirm the AIOS-1 question-order fix behaves correctly in practice (deferred this session in favor of closing) |
| **P5** | Remediate `tools-rfp` (and any other already-bootstrapped consumer) for the `standards`/`docs/integration` path fix | `tools-rfp` was left untouched per explicit owner instruction this session. It still has (or had) stray `.ai/standards/`/`.ai/docs/integration/` content and/or a `.cursorrules` predating this fix. Once approved: `@deploy-basic update` (thin) or `@deploy-files update` (fat) to re-bake `.cursorrules`, migrate any real content out of `.ai/standards/`+`.ai/docs/integration/` into project-root `standards/`+`docs/integration/`, then delete the stray `.ai/`-nested copies. Requires explicit owner go-ahead before touching that repo. |

---

## Current iteration

*(No active iteration - run `@code-implementation plan - M1` after master plan is **Approved** and `implementation-ready: yes`.)*

```markdown
## Current iteration - M{N}: <milestone name>

**Milestone ref:** M{N} · `{MASTER_PLAN}` §<task section>
**Status:** planning | in-progress | complete
**Started:** YYYY-MM-DD

### In scope
- …

### Out of scope (explicit)
- …

### Tasks
| ID | Description | Files | Status | Notes |
|----|-------------|-------|--------|-------|
| M{N}-T1 | … | … | pending | |

### Acceptance criteria
- [ ] …

### Validation steps
- [ ] Tests: `REPLACE:TEST_COMMAND` (per `.cursorrules`)
- [ ] Lint: `REPLACE:LINT_COMMAND`
- [ ] Type: `REPLACE:TYPECHECK_COMMAND`

### Owner blockers
- none

### Concept / NFR registry (this iteration)
| Concept id | Applies | Status | Evidence / trigger |
|------------|---------|--------|-------------------|
| MOD-06 | yes | pending | AI-assisted session |

### Cross-LLM verification
- Triggered: no

### Done this iteration
| Task | Completed | Notes |
|------|-----------|-------|
```
