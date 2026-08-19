# MOD-06 - human commit lane (2026-08-19)

Run per `concepts/ai-amplification/prompt.md` (trigger: agent session modifying framework files).

## AI change risk summary

- AI-assisted: yes
- Boundaries crossed: 0 — doc/rule layer only (`skills/session-control/{skill,reference}.md`, `.cursorrules`, `templates/cursorrules.template`, `CHANGELOG.md`); no hooks, scripts, or module code touched
- New cross-boundary deps: none
- Test isolation: ok — verifiers isolate the changed docs: `scripts/framework-verify.sh` (self-tests + link scan), `scripts/skill-functional-verify.py` (skill.md contract/anchor checks incl. `ANCHOR_CLEAN`), `scripts/touch-scope-verify.sh` (scope), `scripts/blast-radius-check.sh` (risk)
- Human architectural review: optional — doc-level; permission model (Core Principle 8) and no-attribution hooks untouched
- Blast radius: if wrong, agents could mis-report close states in every consumer repo (dirty tree + draft message reported as fail instead of valid pass). Mitigated by keeping `close commit`/`commit` strict (requested commit without SHA = fail) and scoping the lane to plain `close` only.

## Recommendation

merge_with_conditions — reason: low-risk doc change; conditions below.

## Conditions if merge_with_conditions

- All four verifiers exit 0 (`framework-verify`, `skill-functional-verify`, `touch-scope-verify`, `blast-radius-check` no new high risk).
- `close commit` / `commit` strictness preserved verbatim (no SHA → item 6 fail).
- Hooks byte-identical: `prepare-commit-msg` strip + `commit-msg` reject of `Co-authored-by:` untouched (no-attribution invariant).
- `.work/active-ref` retention limited to dirty-tree close (clean-tree close still removes it).
