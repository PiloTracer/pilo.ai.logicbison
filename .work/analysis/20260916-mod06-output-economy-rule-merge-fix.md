# MOD-06 — AI amplification review (2026-09-16)

**Scope reviewed:** session change set — Output economy rule (`.cursorrules` + `templates/cursorrules.template`), deploy-basic merge-scope broadening (`skills/deploy-basic/skill.md`), verifier bake-check anchoring (`scripts/cursorrules-verify.sh` check + `--fix` regex, `scripts/framework-verify.sh` 2h self-test assertion). Earlier same-session commit `e51ed6c` covered the first three files; this review also covers the two script files currently uncommitted.

## AI change risk summary

- AI-assisted: yes (agent session; no `human-only` declaration)
- Boundaries crossed: 1 — deploy/verify tooling (`scripts/`) + its rules/docs surface; single bounded area, no app code
- New cross-boundary deps: none (regex tightening only; no new callers)
- Test isolation: ok — command: `bash scripts/framework-verify.sh` (2h smoke runs the full cursorrules-verify detect → break → `--fix` → re-verify cycle against a scratch target); negative/positive regex cases checked manually (command-position match = 1, illustrative row = 0)
- Human architectural review: optional — single boundary, verifiers green, behavior contract change is narrow (illustrative `.ai/scripts/` rows are now exempt from the bake check by design)
- Blast radius: if wrong, thin-client targets could falsely verify PASS while gate-table commands remain unbaked (`bash .ai/scripts/...` → agents execute a nonexistent path), or `--fix` could rewrite illustrative table rows into absolutes (cosmetic template drift in consumer repos). Mitigation: framework-verify 2h smoke asserts both directions (unbaked command rows still flagged; illustration survives `--fix`); live-confirmed on real target `pizote` (verify PASS post-merge).

## Recommendation

merge_ok — single boundary, isolated smoke coverage, both verifiers exit 0 (`framework-verify: all checks passed`, `skill-functional-verify: PASS`), real-target smoke (pizote) consistent with the new contract.

## Conditions if merge_with_conditions

(none — recommendation is merge_ok)
