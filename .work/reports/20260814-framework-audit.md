# Framework audit — marker detection, deploy-repo removal, full consistency sweep

**Status:** Approved · 2026-08-14
**Needs:** nothing — all fixes applied and verified; structural leftovers tracked in NEXT.md P6.

Audit per `.work/prompts/20260814-marker-detection-deploy-repo-removal-audit.md` item 7, after the marker/detection/deploy-repo changes. Method: three parallel read-only audit sweeps (registry congruence, reference/tooling integrity, skill contract compliance), then targeted fixes.

## Verifier status (post-fix)

| Gate | Result |
|------|--------|
| `framework-verify.sh` | exit 0 (incl. new marker-exclusion self-test in deploy-files smoke) |
| `skill-functional-verify.py` | PASS |
| `touch-scope-verify.sh` | pass (all changed files in declared scope) |
| `blast-radius-check.sh` | risk: high — expected; protected surfaces (`templates/work/**`, `templates/cursorrules.template`, deploy scripts, `SKILL_DEPENDENCIES.md`) touched under owner-approved plan; touch-scope pass |

## Sweep 1 — Registry congruence

All seven canonical registries (`.cursorrules`, `templates/cursorrules.template`, `skills/README.md`, `skills/SKILL_DEPENDENCIES.md`, `README.md`, `PROCESS_ROUTER.md`, `START_HERE.md`) congruent with the 21-skill reality post-deploy-repo-removal.

**Fixed:** `skills/ai-director/reference.md` — stale count ("17 registered skills + 2 deploy utilities" → 21), 5 missing registry rows added (`deploy-basic`, `project-query-setup`, `docs`, `ai-director`, `x-director`), `deploy-files` row completed (`update` + in-place bootstrap), §6 deploy routing aligned with §3 (both deploy modes).

**Noted (no action):** historical entries in CHANGELOG/HANDOFF/`.work/reports/` retain old wording by design (append-only). `.private/CONTEXT.md:79` stale count — untracked local scratch, out of scope.

## Sweep 2 — Reference + tooling integrity

No broken references. All script/hook/workflow/markdown-link targets resolve; hooks (`pre-commit`, `commit-msg`, `prepare-commit-msg`, `post-commit`) installed by `install-git-hooks.sh` all exist; zero live `deploy-repo` references in `templates/`, `scripts/`, `skills/`, `docs/`, `.quick/`; CI workflow points only at existing scripts.

**Fixed:** `.quick/README.md:20` stale "repo clone" deploy-mode mention → "fat-client or thin-client".

## Sweep 3 — Skill contract compliance (21 skills read in full)

**Operator handoff contract:**
- Fixed third-form violation: `skills/code-implementation/reference.md` batch-summary close (3-command menu mislabeled "Form A") → compliant Form B single-command close.
- Fixed shared-engine gap: `skills/probe-protocol.md` now references the contract and its report template closes Form B (callers plan-foundation/plan-master previously added no close).
- Added missing close instructions (12 across 8 skills): `ai-director` ×3, `concept-run` ×2, `feature-spec` (amend), `plan-foundation/reference.md` (greenfield), `plan-master` (greenfield), `project-bootstrap` (init), `project-query-setup` ×3, `x-director` (status).

**Document clarity contract:**
- Fixed template chains: `templates/work/features/.../SPEC.md.template` (+Needs, +Next action), `templates/work/decisions/...ADR template` (+Needs, +Next action), `templates/work/plans/operations/...docker-compose-proposal` (Requires→Needs, +Next action), foundation docs 01–04 templates (+Next action), `templates/work/plans/full/...full-plan.md.template` (+Next action). All 8 verified via framework-verify.

## Structural defects — reported, not fixed (tracked in NEXT.md P6)

Pre-existing (confirmed 2026-08-14, predate this session's changes; verifiers pass despite them):

- `skills/plan-master/skill.md` — orphaned duplicate Implementation-ready text (L345-349), duplicated `### Status report format` heading (L351), orphaned anti-pattern bullets with no parent section (L355-359), duplicated sentence at L182/L186.
- `skills/plan-verify/skill.md` — extensively scrambled: missing `## Brownfield detection` / `## Alignment verify protocol` / `## Integration` headings; 9 orphaned fragments (L101-103, L231, L233, L235-240, L316, L318, L321-329, L369-375).
- `skills/plan-repair/skill.md` — BR0–BR7 duplicated as abbreviated pointer sections (L351-381) under `## Status protocol` with no parent heading.
- `skills/x-director/skill.md` — duplicated step number (`### 5.` twice, L104/L127; latter should be 6).
- `skills/plan-foundation/reference.md` — duplicated consecutive headings (Probe protocol L965/L969, Greenfield protocol L1036/L1040).

**Standards gap (not fixed — gate impact):** `standards/20260517-FEATURE_STANDARD.md` §3 and `standards/20260519-MASTER_PLAN_STANDARD.md` do not mandate the Needs line / `## Next action` the Document clarity contract requires; templates now carry them, but conformance gates (`master-plan-verify.sh`) don't check them. Recommend a dedicated pass — changing the 25-section standard touches `master-plan-verify.sh` expectations.

## Next action

`@session-control close` when ready — or continue with NEXT.md P1 (deploy to tools-project).
