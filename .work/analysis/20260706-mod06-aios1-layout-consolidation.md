## AI change risk summary

- AI-assisted: yes
- Blast radius: if broken, consumer bootstrap scaffolds wrong paths (standards/integration outside `.work/`), thin-client deploy creates stray `.ai/`, or agents read stale layout from `.cursorrules`/skills — breaking adopters on `@deploy-basic` / `@plan-foundation greenfield`.
- Scope: 40+ files across templates, bootstrap scripts, skills, standards templates, and self-hosted `.cursorrules`; protected deploy surfaces touched with declared touch-scope.

## Recommendation

merge_ok

## Conditions if merge_with_conditions

- Run `bash scripts/framework-verify.sh` and `python3 scripts/skill-functional-verify.py` before commit (exit 0 required).
- Tag v0.5.2 after commit; run P1 deploy to `tools-project` before treating consumers as migrated.
- P5 consumer remediation (`tools-rfp`) still requires explicit owner approval.
