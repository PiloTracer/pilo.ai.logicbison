# CI/CD conventions (Agent OS consumers)

**Status:** Approved · **Needs:** nothing for read-only adoption

## Principles

1. **Reuse framework scripts** — do not fork `gate-verify.sh` / `framework-verify.sh` logic into bespoke CI YAML.
2. **Evidence in repo** — iteration tasks marked `done` in `NEXT.md` must cite gate evidence (`gate-verify.sh` enforces).
3. **Optional last-gate artifact** — `.work/reports/last-gate.json` may be uploaded as a CI artifact for session continuity (not required on every repo).
4. **No secrets in workflows** — use GitHub encrypted secrets / `TF_VAR_*`; never commit tokens.

## Required checks (recommended minimum)

| Check | Command |
|-------|---------|
| Framework smoke | `bash scripts/framework-verify.sh` (thin-client: run from `$AGENT_OS_SOURCE` against consumer tree) |
| Skill integrity | `python3 scripts/skill-functional-verify.py` (framework source only) |
| Gate evidence | `bash scripts/gate-verify.sh` |

## Next action

`@cicd-github install` in the consumer repo.