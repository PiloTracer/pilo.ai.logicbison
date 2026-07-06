# AI amplification review — full framework audit remediation

**Date:** 2026-07-06  
**Concept:** MOD-06 (ai-amplification)  
**Trigger:** AI-assisted diff produced during agent-led full-repo audit and remediation.

---

## AI change risk summary

- **AI-assisted:** yes
- **Boundaries crossed:** 5 — `scripts/`, `skills/`, `templates/`, `docs/`, `.work/`
- **New cross-boundary deps:** none (all changes are mechanical fixes, doc corrections, and scaffold alignment; no new imports, RPC, shared models, or shared DB access)
- **Test isolation:** ok — command: `python3 scripts/skill-functional-verify.py && bash scripts/framework-verify.sh`
- **Human architectural review:** required — reason: diff crosses >1 hard boundary and touches protected surfaces (`scripts/framework-verify.sh`, `templates/bootstrap.sh`, `templates/cursorrules.template`)
- **Blast radius:** If these changes are wrong, the framework verification suite could fail on consumer bootstrap smoke tests, the `.cursorrules` placeholder map could mislead adopters, or the bootstrap scaffold could omit `.work/reports/`. No production data or runtime services are affected; the risk is to framework correctness and new-repo onboarding.

---

## Recommendation

**merge_with_conditions**

The remediation is mechanical and verification suites pass, but the cross-area nature and protected-surface touches warrant human eyes on the diff before it reaches `main`.

---

## Conditions if merge_with_conditions

- [ ] `python3 scripts/skill-functional-verify.py` passes.
- [ ] `bash scripts/framework-verify.sh` passes.
- [ ] `bash scripts/touch-scope-verify.sh` passes (scope declared in `.work/touch-scope`).
- [ ] Reviewer confirms the new `.cursorrules` placeholder entries do not conflict with consumer-specific tokens.
- [ ] Reviewer confirms `templates/bootstrap.sh` addition of `.work/reports/` does not break existing consumer updates.
