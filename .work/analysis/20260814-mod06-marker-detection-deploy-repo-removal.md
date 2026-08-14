# MOD-06 — marker detection + deploy-repo removal + audit fixes (2026-08-14)

Session ref: AIOS-1 · Plan: `.work/prompts/20260814-marker-detection-deploy-repo-removal-audit.md`

## AI change risk summary
- AI-assisted: yes (agent session; parallel coder subagents applied audit fixes)
- Boundaries crossed: >1 — skills docs, deploy scripts, templates, standards (PROTECTED_SURFACES), routing docs, `.work/` memory — this is a framework-meta change, not app code; no runtime module boundaries exist in this repo (`estimated`)
- New cross-boundary deps: none — no new imports/RPC/shared state; one new filesystem convention (`agent.os.framework.md` existence check in `scripts/deploy-basic.sh` + session-control docs) (`measured` — grep + verifier runs)
- Test isolation: ok — command: `bash scripts/framework-verify.sh` (deploy smokes exercise deploy-files/deploy-basic end-to-end incl. the new marker validation + exclusion assertions); `python3 scripts/skill-functional-verify.py` (skill contract checks); `bash scripts/touch-scope-verify.sh` (`measured` — all exit 0 this session)
- Human architectural review: optional — reason: >1 boundary crossed, but every change is docs/scripts in the framework repo with mechanical verification green; protected-surface edits were pre-approved via the operator-approved plan
- Blast radius: if the marker exclusion in `scripts/deploy-files.sh` were wrong, consumers would receive `agent.os.framework.md` and session-control would misdetect them as framework source (whole-repo commits) — caught by the new framework-verify self-test. If `deploy-basic.sh` marker validation were wrong, thin-client bootstrap would block — exercised in framework-verify smokes (exit 0). Removing deploy-repo breaks consumers that reference `@deploy-repo` — none exist in-repo (grep-verified); external consumers learn via CHANGELOG. Doc-template changes affect only future generated documents.

## Recommendation
merge_ok — reason: all four gates green; deletions operator-authorized; high blast radius is expected for framework-meta work and every risky path is covered by a mechanical check.

## Notes
- `blast-radius-check.sh` verdict: `risk: high`, exit 2 (warn) — expected; protected surfaces (`templates/work/**`, `templates/cursorrules.template`, deploy scripts, `skills/SKILL_DEPENDENCIES.md`) were edited under the owner-approved plan; touch-scope pass confirms nothing outside declared scope.
- Pre-existing structural defects (plan-master/plan-verify/plan-repair/x-director/plan-foundation-reference) were deliberately NOT fixed here — tracked in NEXT.md P6, detailed in `.work/reports/20260814-framework-audit.md`.
