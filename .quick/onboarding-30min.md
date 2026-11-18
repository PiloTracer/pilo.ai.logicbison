# Onboarding in 30 minutes (lite path)

**Goal:** Working session memory + honest gates on an **existing** repo.

```bash
# From consumer repo root (thin-client already deployed):
@project-bootstrap quickstart - lite
@session-control start
```

Then in chat:

```text
@project-bootstrap status          # unfilled REPLACE: tokens
@session-control start
# edit .work/plans/NEXT.md — one Recommended next row
# implement one small change
@code-verify uncommitted
@session-control close
```

**Stack-specific:** after bootstrap, `bash $AGENT_OS_SOURCE/scripts/apply-stack-pack.sh spring-boot .` and merge per `templates/stacks/spring-boot/README.md`.

**CI:** `@cicd-github install` when ready for PR checks.

**Full lifecycle map:** `.quick/software-lifecycle.md`