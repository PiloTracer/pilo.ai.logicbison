## AI change risk summary

- AI-assisted: yes
- Boundaries crossed: 1 — skills/session-control (docs-only; synced `.cursorrules` + template wording)
- New cross-boundary deps: none
- Test isolation: ok — command: `python3 scripts/skill-functional-verify.py` + `bash scripts/touch-scope-verify.sh` (session-control is in `ANCHOR_CLEAN`/`TRIMMED` sets; anchor + required-section checks cover the edited files)
- Human architectural review: optional — docs-only behavior contract change; no code paths
- Blast radius: if wrong, `close commit` / `commit` would stage the wrong scope in consumer repos (either `.ai/` + app dirs leaking into session commits, or bookend-only commits leaving untracked `.work/` artifacts behind). The `.work/`-only default with untracked inclusion matches the stated requirement; verify gates confirm anchor/registry integrity.

## Recommendation

merge_ok

## Conditions if merge_with_conditions

- Run `python3 scripts/skill-functional-verify.py` + `bash scripts/touch-scope-verify.sh` + `bash scripts/framework-verify.sh` (exit 0) before commit.
- Confirm with owner that `.work/`-only default (instead of full safe tree) is the intended scope for session commits in consumer repos.
