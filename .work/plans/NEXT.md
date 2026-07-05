# NEXT - planning backlog

> **This is a template file.** In your adopter repo it is maintained by **`@code-implementation`** (the `## Current iteration` block) and **`@session-control close`** (the `## Recommended next` row). In this framework repo it stays as a demo skeleton.

**Updated:** 2026-07-04

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

---

## Blocked on owner

| # | Item | Notes |
|---|------|-------|
| - | (none) | |

---

## Recommended next

| Priority | Item | Notes |
|----------|------|-------|
| **P1** | Deploy v0.4.4 to tools-project | `@deploy-files copy - /path` or `@deploy-basic update` on thin-client adopters |

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
