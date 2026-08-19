# IaC Conventions — Terraform

**Status:** Template — adopt per project; binding once copied under `.work/standards/`.
**Updated:** 2026-08-19
**Pairs with:** `skills/infra-terraform/`, `concepts/declarative-infra/` (MOD-08), `concepts/cost-model/` (MOD-03), `.cursorrules` Core Principle 8.

---

## 1. Repo layout

```text
infra/
├── modules/        ← reusable modules (network, database, service, …)
└── envs/           ← thin root configs per environment
    ├── dev/
    ├── staging/
    └── prod/
```

- Resources live in `modules/`; `envs/<env>/` holds backend config, provider pins, module calls, env variables.
- One state key per environment. Default strategy: **directory-per-env** (workspaces acceptable for structurally identical envs - record the choice in an ADR).

---

## 2. State

- **Remote state is mandatory for shared environments** (anything beyond one developer's experiment). Local state is dev-only.
- **State locking on** - S3 + DynamoDB, Terraform Cloud, or equivalent.
- State bucket/container: versioning on, encryption on, public access blocked. State can contain sensitive values - treat it as secret-bearing.
- **Never edit state by hand.** `terraform state mv/rm` only with explicit approval and a recorded reason.

---

## 3. Plan-review gate

- Every `apply` on shared infra is preceded by a **human-reviewed, human-readable plan** (`terraform plan -out`).
- Destroys and replacements are called out by name in the review.
- Apply the saved plan file (`terraform apply tfplan-<env>`); never `-auto-approve` on shared envs.
- First apply to shared infra: run MOD-08 (`concepts/declarative-infra/prompt.md`) and attach the output.

---

## 4. Drift policy

- Scheduled `terraform plan -detailed-exitcode` per shared env (CI cron or runbook); **alert on exit 2**.
- Drift remediation is a reviewed plan like any other change - never auto-apply from a scheduled job.
- Console/manual changes are codified (import) or reverted (apply); the decision is recorded in an ADR.

---

## 5. Destroy discipline

- Destroy is **manual, approved, and never a CI default** (`.cursorrules` Core Principle 8).
- Requires explicit human approval in the same message naming the env and the full destroy list from `terraform plan -destroy`.

---

## 6. Tagging and cost

- Every billable resource carries the standard tag set: `project`, `env`, `owner`, `cost-center`.
- New billable units (cluster, NAT gateway, log index, …) get a monthly estimate band per MOD-03 (`concepts/cost-model/prompt.md`) before apply; cost-threshold crossings get an ADR with `$`.

---

## 7. Secrets policy

- No secrets in `.tf`, `*.tfvars`, or committed state-adjacent files.
- Prefer secrets-manager `data` sources → `TF_VAR_*` env vars → gitignored `.tfvars`, in that order.
- `.gitignore` covers `*.tfstate*`, `.terraform/`, non-example `*.tfvars`, `crash.log`.

---

## 8. Version pinning

- `terraform { required_version = ">= …" }` and `required_providers` pinned in every root config.
- `.terraform.lock.hcl` is **committed**; provider upgrades go through the plan-review gate like any other change.
