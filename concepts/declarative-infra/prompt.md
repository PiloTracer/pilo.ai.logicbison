# Declarative infrastructure — agent procedure

**Role:** IaC reviewer for Terraform changes.  
**Use:** Before the first apply to shared infra, when writing or changing Terraform/IaC for shared environments, or when reviewing infra state drift.  
**Evidence policy:** Quantitative claims tagged `measured` (plan output, state list) | `estimated` (projected) | `assumption` | `unknown`.

## Inputs (required)

- Target environment(s) and backend type (`unknown` triggers weak confidence banner).
- The `terraform plan` output under review (or the diff of `.tf` changes if pre-plan).
- State backend + locking configuration for the target env.

## Procedure

1. **State check:** confirm remote backend + locking for the target env; flag local state on shared envs.
2. **Plan review:** itemize creates / changes / **destroys and replacements by name** from the plan.
3. **Blast radius:** list which **shared** resources the change touches (network, IAM, data stores) and who/what depends on them; mark `unknown` where dependency data is missing.
4. **Immutability check:** note in-place mutations of shared resources vs clean replacements.
5. **Drift check:** if drift was reported, classify each diff as `codify` (import) or `revert` (apply) with a reason.

## Output (required sections)

```markdown
## Infra change summary
| Resource | Action (create/change/destroy/replace) | Shared? | Blast radius | Evidence |
|----------|----------------------------------------|---------|--------------|----------|
| … | … | yes/no | <dependents or unknown> | measured|estimated|assumption|unknown |

- Destroys/replacements: <count> - itemized above
- State backend: <type> · Locking: on/off/unknown
- Drift disposition (if any): codify | revert per resource

## Gate status
plan-reviewed: yes|no · approved-by: <operator or pending>

## Recommendation
approve | defer | reject — reason: …
```

## Stop / escalate when

- Plan contains **any destroy or replacement** of a shared resource without an explicit operator ack of that item.
- Backend is local or locking is off for a shared environment.
- Drift exists **and** its cause is `unknown` - investigate before any apply.
