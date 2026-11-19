# MOD-06 — language decision cards (2026-11-18)

## AI change risk summary

- AI-assisted: yes
- Boundaries crossed: 2 — `skills/code-implementation`, `standards/language` (plus a pointer in `standards/20260517-CONVENTIONS.md` and a changelog line)
- New cross-boundary deps: none — the skill reads the selector; it does not import a package
- Test isolation: ok — `bash scripts/skill-functional-verify.py` and `bash scripts/framework-verify.sh` fail when the skill anchors or the standards tree break. No application runtime in this repo.
- Human architectural review: optional — docs and a skill procedure, no deploy path
- Blast radius: a consumer agent that ignores the selector loads nothing new. A consumer agent that matches the signal must state a model before editing. Wrong card text would bias concurrency choices until the ledger drops the rule.

## Recommendation

merge_with_conditions — topic cards replace the concurrency-only cut. Paired keep/drop runs did not happen. The cards do not feed `p2-backend`.

## Conditions if merge_with_conditions

- Must add tests: none in this repo. `framework-verify` is the gate.
- Must split PR: no
- Ledger stays `unmeasured` until a scratch consumer records a with-card and a without-card run (`standards/language/README.md`).

Evidence: `assumption` on behavior change. `measured` on the 2026-11-18 HTTP checks in `standards/language/20261118-SOURCES.md`.
