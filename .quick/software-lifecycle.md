# Software lifecycle with Agent OS

| Phase | What you do | Skills |
|-------|-------------|--------|
| **Create / adopt** | Bootstrap rules + `.work/` | `@project-bootstrap init`, `@deploy-basic`, `apply-stack-pack.sh` |
| **Plan** | Scope, master plan, SPECs | `@plan-foundation`, `@plan-master`, `@feature-spec intake` |
| **Develop** | Milestone tasks in `NEXT.md` | `@code-implementation start/continue` |
| **Track** | Session + backlog truth | `@session-control`, HANDOFF, NEXT, task registry |
| **Verify** | Tests, lint, plans, diffs | `@code-verify`, `@plan-verify`, `gate-verify.sh` |
| **Debug / fix** | Close verifier gaps | `@code-repair`, `@plan-repair` |
| **Follow-up** | Hand off to next session | `@session-control close`, `last-gate.json` |
| **Improve** | Architecture / NFR prompts | `@concept-run`, MOD packs |
| **Deliver** | CI + infra | `@cicd-github`, `@infra-terraform`, `@dev-stack` |
| **Env hygiene** | `.env` parity | `@env-sync` |

```text
create → plan → develop ⇄ verify → debug → track → deliver → improve
              ↑______________ session-control bookends ______________|
```

**Lost?** `@process-router - <question>` or `@ai-director - <goal>`