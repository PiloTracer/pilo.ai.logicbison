# NEXT - planning backlog

> **This is a template file.** In your adopter repo it is maintained by **`@code-implementation`** (the `## Current iteration` block) and **`@session-control close`** (the `## Recommended next` row). In this framework repo it stays as a demo skeleton.

**Updated:** 2026-08-19

---

## Done

| Item | Artifact |
|------|----------|
| Spring Boot stack pack + Terraform support (2026-08-19, uncommitted) | `templates/stacks/spring-boot/` (6 fragments); `java-spring-boot` option in `plan-foundation` p2-backend; `skills/infra-terraform/` (init/plan/apply/status/drift/destroy; plan-review gate, destroy hard stop; in `ANCHOR_CLEAN`); `standards/20260819-IAC_CONVENTIONS.md`; MOD-08 `concepts/declarative-infra/`; registry wiring (`.cursorrules`, template, `skills/README.md`, `ai-director/reference.md`, `SKILL_DEPENDENCIES.md` matrix + verbs, README 22 skills, MOD-01…08 sweep); MOD-06 `.work/analysis/20260819-mod06-spring-boot-terraform-support.md`; draft plan `.work/plans/20260819-v07-tech-expansion-draft-plan.md`; review `.work/feedback/20260819-uncommitted-review.md` repaired (I1–I6, G1/G2/G7); all verifiers pass, blast-radius warn (protected, owner-approved) |
| Marker detection + deploy-repo removal + full framework audit (2026-08-14) | `agent.os.framework.md` marker (protected, never deployed); marker-only repo-mode detection (`skills/session-control/{skill,reference}.md`, `.cursorrules`, template); `deploy-repo` skill+script removed (21 skills; ~20 refs cleaned); clarity prompts synced to contracts (Rule 6, Form A/B, Status headers); audit fixes (`ai-director/reference.md` registry → 21, `probe-protocol.md` bound, `code-implementation` close fix, 12 handoff closes, 8 `templates/work/**` docs); `.work/reports/20260814-framework-audit.md`, `.work/analysis/20260814-mod06-marker-detection-deploy-repo-removal.md`; all verifiers exit 0 |
| Operator handoff + Document clarity contracts (2026-08-14) | `skills/SKILL_DEPENDENCIES.md` §§ Operator handoff / Document clarity; all 22 skills + report templates; `docs`/`plan-foundation`/`plan-master`/`feature-spec` + docs/foundation/full-plan templates; verifier enforcement (`DOC_GENERATING`); `.cursorrules` + template + `skills/README.md` + `CHANGELOG.md`; protocols at `.work/prompts/improve-clarity-of-{responses,documentation}.md`; all verifiers pass |
| session-control repo-mode commit scope (2026-08-14) | Whole-repo commits in framework source; `.work/` + general root files in consumers; `skills/session-control/{skill,reference}.md`, `.cursorrules`, `templates/cursorrules.template`, `skills/README.md`, `CHANGELOG.md` [Unreleased]; `framework-verify` + `skill-functional-verify` + `touch-scope-verify` pass |
| plan-foundation evidence-based stack grills (2026-08-12, commit `70dc9a1`) | `skills/plan-foundation/{skill,reference}.md`, `.work/analysis/20260812-mod06-plan-foundation-stack-grill-gaps.md` |
| Full framework audit + gap remediation (2026-07-06) | `.work/reports/full-audit-report.md`, `.work/analysis/20260706-mod06-full-audit.md`; `framework-verify` + `skill-functional-verify` + `touch-scope-verify` pass |
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
| v0.5.2 layout consolidation + audit fixes (2026-07-06) | `.work/standards/` + `.work/docs/integration/` as sole project-owned customization paths; `@deploy-basic` never creates local `.ai/`; bootstrap purges deprecated repo-root scaffolds; deploy-basic patches legacy cursorrules paths; MOD-07 sweep; anchor hygiene (9 skills → `ANCHOR_CLEAN`); greenfield registry ordering (U2 closed); MOD-06 output `.work/analysis/20260706-mod06-aios1-layout-consolidation.md`; `framework-verify` + `skill-functional-verify` exit 0 |
| Master-plan-standard fix from external smoke-test feedback (2026-07-06) | Confirmed root cause: `templates/work/plans/full/YYYYMMDD-full-plan.md.template` shipped only 11/25 mandatory `MASTER_PLAN_STANDARD.md` H2 sections — fixed to all 25 in order; new `scripts/master-plan-verify.sh` (section completeness/ordering + Approved↔integrity consistency), wired into `@plan-verify master` M3 + `framework-verify.sh` self-test; `plan-foundation` GF0 warns on placeholder `.work/touch-scope`; `MASTER_PLAN_STANDARD.md` §References updated; `CHANGELOG.md` [Unreleased]; MOD-06 output `.work/analysis/20260706-mod06-master-plan-standard-fix.md`; `framework-verify` + `skill-functional-verify` exit 0 |
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
| **P1** | Deploy v0.5.2 layout consolidation + prior fixes to tools-project | `@deploy-files copy - /path` or `@deploy-basic update` — propagates `.work/standards/` + `.work/docs/integration/` layout, token-optimized rules, repaired `plan-foundation/skill.md`, thin-client script-path baking, legacy cursorrules path patching, the master-plan-standard fix (fixed `full-plan.md.template`, `master-plan-verify.sh`), the repo-mode session-control commit scope (2026-08-14), **and** both clarity contracts (Operator handoff + Document clarity, 2026-08-14). Also propagates the marker-only detection wording + audit conformance fixes (2026-08-14); the marker itself is never deployed (deploy-files excludes it), and `deploy-repo` no longer exists. Resolve source path from the live `.ai` repo at invocation time (`deploy-files.sh`/`deploy-basic.sh` derive `AI_ROOT` from the invoked script path). |
| **P2** | ~~Cross-skill anchor-hygiene cleanup~~ | **Done 2026-07-06** — 8 skills repaired; promoted to `ANCHOR_CLEAN` in `skill-functional-verify.py` |
| **P3** | ~~Clarify greenfield P0 registry-creation ordering~~ | **Done 2026-07-06** — greenfield step 3 creates registries before `p0-probe`; U2 closed |
| **P4** | Live greenfield walkthrough | Run `@plan-foundation greenfield` end-to-end on a scratch/test project now that `skill.md` is structurally clean, to confirm the AIOS-1 question-order fix behaves correctly in practice (deferred this session in favor of closing) |
| **P5** | Remediate `tools-rfp` (and any other already-bootstrapped consumer) for layout consolidation | `tools-rfp` was left untouched per explicit owner instruction. It may still have stray `.ai/standards/`/`.ai/docs/integration/`, deprecated repo-root `standards/`/`docs/integration/`, and/or a `.cursorrules` predating the `.work/standards/` layout. Once approved: `@deploy-basic update` (thin) or `@deploy-files update` (fat) to re-bake `.cursorrules`, migrate any real content into `.work/standards/` + `.work/docs/integration/`, purge deprecated repo-root scaffolds (bootstrap does this when empty), then delete stray `.ai/`-nested copies. Requires explicit owner go-ahead before touching that repo. |
| **P6** | Structural cleanup: `plan-master` + `plan-verify` skill.md (+ plan-repair, x-director, plan-foundation/reference.md) | Pre-existing, flagged during the 2026-08-14 operator-handoff rollout (not introduced by it): `skills/plan-master/skill.md` ~lines 339-352 have a duplicated "Status report format" heading and an unlabeled anti-patterns list inside the Probe protocol section; `skills/plan-verify/skill.md` has orphaned alignment/coverage fragments near end of file. Both pass all verifiers; cosmetic/structural only. **Extended 2026-08-14** by the full audit (`.work/reports/20260814-framework-audit.md`): plan-master also has orphaned Implementation-ready dup (~L345-349) + duplicated sentence (L182/L186); plan-verify is extensively scrambled (missing `## Brownfield detection` / `## Alignment verify protocol` / `## Integration` headings, 9 orphaned fragments ~L101-375); `skills/plan-repair/skill.md` BR0–BR7 duplicated as pointer sections (~L351-381) under `## Status protocol`; `skills/x-director/skill.md` duplicated step number (`### 5.` twice, ~L104/L127); `skills/plan-foundation/reference.md` duplicated consecutive headings (~L965/L969, ~L1036/L1040). Also: standards gap — FEATURE_STANDARD §3 / MASTER_PLAN_STANDARD don't mandate Needs/`## Next action` (templates now carry them; gates don't check). |
| **P7** | Terraform workflow guide + vendor integration cache | From `.work/feedback/20260819-uncommitted-review.md` G3/G4: add `docs/guides/workflows/` terraform-iac guide; cache Terraform state-backend/provider docs under `.work/docs/integration/` with `MANIFEST.txt` entries (§External integration docs rule). |
| **P8** | Dogfood the new packs (smoke build) | From review G5: scratch consumer project → apply `templates/stacks/spring-boot/` → `@dev-stack` up (Docker build + compose) → `@infra-terraform plan` against a sandbox account. Clears the `assumption` tags in the MOD-06 output. |
| **P9** | Stack-pack application helper | From review G6: `templates/stacks/` packs are manual copy-paste; consider a script or `project-bootstrap` mode that applies a pack (cf. `dev-stack`'s `bin/start.sh` precedent). |
| **P10** | Remaining v0.7 draft-plan rows | `.work/plans/20260819-v07-tech-expansion-draft-plan.md`: `infra-aws`, `infra-ansible`, `cicd-github` skills + cloud-security-baseline/CICD_CONVENTIONS standards + MOD-09 + node-react/python stack packs — deferred; scope decision needed before scheduling (rows 5, 6, 8, 9 of the draft). |

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
