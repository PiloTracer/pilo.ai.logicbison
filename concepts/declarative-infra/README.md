# Declarative infrastructure — state as source of truth

**Pack id:** MOD-08  
**Directory:** `declarative-infra/`  
**Source chain:** [Concepts pack](../README.md) plus Agent OS IaC conventions (`standards/20260819-IAC_CONVENTIONS.md`).

## Why this matters for AI-assisted coding

Agents will happily `apply` whatever the config says - that is the point of IaC and also its danger. Declarative infrastructure makes **state the source of truth** and the **plan the review artifact**: the diff between desired and actual is computed, reviewed, and only then applied. Without that gate, one generated `.tf` block can destroy a shared environment faster than any hand-typed command.

## Signals (detect)

| Signal | Interpretation |
|--------|----------------|
| `apply` proposed **without** a reviewed plan | Ungated mutation of shared infra |
| Local `*.tfstate` for a shared environment | State of truth lives on one laptop; locking impossible |
| Drift found by accident, not by schedule | No drift detection; console changes accumulating silently |
| `terraform destroy` in a CI default path | Destructive op without per-run approval |
| Secrets in `.tf` / `*.tfvars` plaintext | Credential leak + secret-bearing state |

**Epistemic note:** "Plan before apply" and "remote state with locking" are vendor-documented practice, not transcript claims - verify against the Terraform docs for your version.

## Rules / gates

1. **State is the source of truth.** Config declares desired state; the plan reconciles. Never hand-edit state files.
2. **Plan-review is a gate.** No apply to shared infra without a human-readable, human-approved plan.
3. **Drift is measured, not assumed.** Scheduled `plan -detailed-exitcode`; alert on diff.
4. **Immutability by default.** Replace over mutate where the provider supports it; treat in-place mutation of shared resources as review-worthy.
5. **Blast radius is named.** Every plan review states which shared resources are touched; every destroy is itemized before approval.

## Anti-patterns

- "It's just dev" reasoning applied to a state file shared by the team.
- Auto-approve flags in scripts or CI for shared environments.
- Reconciling drift by applying from an unreviewed branch.

## Limits (what AI cannot verify alone)

- Whether the remote backend's locking and encryption are actually configured (cloud-side settings).
- True cost of a plan's new billable units - pair with MOD-03 (cost-model).
- Organizational approval policy for destroys (who may approve what).

## Related concepts

- [MOD-03 — Cost model](../cost-model/README.md)
- [MOD-01 — Coupling audit](../coupling-audit/README.md)
- [MOD-04 — Ops headcount](../ops-headcount/README.md)

## Agent procedure

See [`prompt.md`](prompt.md).
