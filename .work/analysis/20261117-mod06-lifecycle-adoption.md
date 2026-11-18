# MOD-06 — lifecycle adoption pack (2026-11-17)

## AI change risk summary

- AI-assisted: yes
- Boundaries crossed: 1 — framework source docs/scripts/skills (no consumer app runtime, no schema)
- New cross-boundary deps: none
- Test isolation: ok — command: `bash scripts/framework-verify.sh` (section 11 includes env-sync-test, bootstrap-smoke, apply-stack-pack --list, last-gate-record)
- Human architectural review: optional — reason: additive skills and scripts; protected paths were already in this change set
- Blast radius: a broken `bootstrap-smoke.sh` or `last-gate-record.sh` fails `framework-verify` section 11 and would fail the new GitHub workflow on the framework repo. `apply-stack-pack.sh` copies only missing files, so an existing consumer file is left in place. `quickstart` is specified to write `.work/plans/QUICKSTART-PLAYBOOK.md` and to leave HANDOFF and NEXT untouched. Pizote is a thin client of this working tree (`AGENT_OS_SOURCE=/mnt/work/Projects/pilo.ai.logicbison`); uncommitted edits here are what that repo's agent reads. Nothing here changes Pizote product code.

## Recommendation

merge_with_conditions — reason: the pack matches the Pizote lite playbook, but protected paths are in the diff and two registries were not updated.

## Conditions if merge_with_conditions

- Must add tests: section 11 smokes cover the new scripts; no further test required for this pack.
- Must split PR: no.
- Owner approval before commit for protected paths: `scripts/framework-verify.sh`, `skills/SKILL_DEPENDENCIES.md`, `templates/work/plans/QUICKSTART-PLAYBOOK.md` (`standards/PROTECTED_SURFACES.json`).
- Do not stage untracked junk `1` (shell error text). `.work/reports/last-gate.json` is gitignored.
- `.cursorrules` and `templates/cursorrules.template` still omit `cicd-github` (24-skill tables). Those files were not edited; they need a same-message yes before a registry row is added.
