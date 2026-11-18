# cicd-github — reference

## Template

| File | Purpose |
|------|---------|
| `templates/ci/github-actions/framework-gates.yml` | PR/push smoke: `framework-verify`, `skill-functional-verify`, `gate-verify` |

## Thin-client note

Consumer repos point `AGENT_OS_SOURCE` at the framework tree. CI options:

1. **Checkout consumer only** — run `REPLACE:TEST_COMMAND` / lint / type from `.cursorrules` + `bash $AGENT_OS_SOURCE/scripts/gate-verify.sh .work/plans/NEXT.md`.
2. **Checkout framework + consumer** — multi-repo workflow (advanced); not templated here.

## Related

- `standards/20261117-CICD_CONVENTIONS.md`
- `@code-verify uncommitted` may write `.work/reports/last-gate.json` via `scripts/last-gate-record.sh`