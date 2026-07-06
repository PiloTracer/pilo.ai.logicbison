## AI change risk summary

- AI-assisted: yes
- Blast radius: `templates/work/plans/full/YYYYMMDD-full-plan.md.template` and `scripts/framework-verify.sh` are on `standards/PROTECTED_SURFACES.json`; owner approved in-message after the fact (process gap: PROTECTED_SURFACES.json should be checked *before* editing, not after — noted for future sessions). If broken: `@plan-master greenfield` would keep shipping plans missing 14/25 mandatory `MASTER_PLAN_STANDARD.md` sections (the exact bug this fix closes), or `framework-verify.sh` could false-pass/false-fail on the new self-test block.
- Scope: 8 files — `templates/work/plans/full/YYYYMMDD-full-plan.md.template`, `scripts/master-plan-verify.sh` (new), `scripts/framework-verify.sh`, `skills/plan-verify/reference.md`, `skills/plan-foundation/skill.md`, `standards/20260519-MASTER_PLAN_STANDARD.md`, `CHANGELOG.md`, `.work/touch-scope` — all within declared touch-scope (`touch-scope-verify.sh` pass).

## Recommendation

merge_ok

## Conditions if merge_with_conditions

- Run `bash scripts/framework-verify.sh` before commit (exit 0 required) — includes 3 new `master-plan-verify.sh` self-test cases (missing sections, Approved+pending integrity, fully conformant).
- Run `python3 scripts/skill-functional-verify.py` before commit (exit 0 required).
