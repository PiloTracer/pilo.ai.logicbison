# Framework evolution plan — software lifecycle support

**Status:** Approved for execution · **Updated:** 2026-11-17  
**Needs:** Owner priority among consumer deploy (P1) vs greenfield CI smoke  
**Task ref:** AIOS-1

Agent OS goal: facilitate **creating** software projects, **developing** with gates, **tracking** plans and iterations, **debugging** via verify/repair, **follow-up** via HANDOFF/NEXT, and **continuous improvement** via concepts and standards — without bloating skills.

## Milestones

| ID | Name | Outcome | Status |
|----|------|---------|--------|
| M1 | Adoption quick wins | `quickstart` + `stack` bootstrap modes, onboarding cheat sheets, stack apply script | **landed** |
| M2 | Trust ledger | `last-gate.json` + `code-verify` records; `gate-verify` in CI template | **landed**. Close does not read the ledger yet |
| M3 | Delivery plane | `cicd-github` skill + workflow templates + CICD standard | **landed** |
| M4 | Verification in CI | `env-sync-test` + `bootstrap-smoke` in `framework-verify` | **landed** |
| M5 | v0.7 expansion | AWS/ansible packs, python/node stack packs, P6 skill trim | planned |

## M1 — Adoption

- `@project-bootstrap quickstart - lite|brownfield|full` → writes `.work/plans/QUICKSTART-PLAYBOOK.md` only (no HANDOFF or NEXT edits) and prints that mode's 7-step table.
- `scripts/apply-stack-pack.sh` — non-destructive copy from `templates/stacks/<pack>/`.
- `.quick/onboarding-30min.md`, `.quick/software-lifecycle.md`.

## M2 — Trust

- `scripts/last-gate-record.sh` writes `.work/reports/last-gate.json` (commands, exit codes, verifier, timestamp).
- `@code-verify uncommitted` **should** call record script on pass/pass-with-conditions.

## M3 — Delivery

- `skills/cicd-github/` — install/verify/status; wires existing `gate-verify.sh`, `framework-verify.sh`, `skill-functional-verify.py`.
- `templates/ci/github-actions/framework-gates.yml`.

## M4 — CI self-test

- `scripts/bootstrap-smoke.sh` — temp dir bootstrap; required files non-empty.
- `framework-verify` section 11: env-sync-test + bootstrap-smoke.

## Next action

`bash scripts/framework-verify.sh` after merging M1–M4 artifacts; then `@deploy-basic update` on approved consumers (P1).