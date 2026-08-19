# infra-terraform - reference

Supplement to `skill.md`. Invocation examples, backend templates, and detailed protocols.

---

## Invocation examples

| Action | Prompt |
|--------|--------|
| Set up backend + state | `@infra-terraform init` |
| Produce review plan | `@infra-terraform plan - staging` |
| Apply approved plan | `@infra-terraform apply - staging` |
| Check drift | `@infra-terraform drift` |
| Report state | `@infra-terraform status` |
| Destroy (HARD STOP) | `@infra-terraform destroy - dev` |

### Cursor

```
@infra-terraform init
@infra-terraform plan - staging
@infra-terraform drift
```

### Claude Code / opencode / Codex

```
Follow .ai/skills/infra-terraform/skill.md - plan. Target: staging.
Follow .ai/skills/infra-terraform/skill.md - drift.
```

---

## Mode comparison

| | init | plan | apply | status | drift | destroy |
|---|------|------|-------|--------|-------|---------|
| Writes .tf config | yes | no | no | no | no | no |
| Touches state | no | refresh-only | yes | no | refresh-only | yes |
| Touches infrastructure | no | no | yes | no | no | yes |
| Requires approved plan | no | no | yes | no | no | yes (destroy list) |
| Requires same-message approval | no | no | shared envs | no | no | **always** |
| Read-only | no | yes | no | yes | yes | no |

---

## State backends

| Backend | Locking | Use for |
|---------|---------|---------|
| S3 + DynamoDB | yes (`dynamodb_table` or `use_lockfile`) | Shared envs on AWS |
| Terraform Cloud / HCP | yes (built in) | Teams wanting managed state + runs |
| GCS / Azure Blob | yes | Shared envs on GCP / Azure |
| local | none | **Dev-only experiments; never shared envs** |

### S3 backend skeleton

```hcl
terraform {
  backend "s3" {
    bucket         = "<org>-tfstate"
    key            = "<project>/<env>/terraform.tfstate"
    region         = "<region>"
    dynamodb_table = "<org>-tfstate-lock"
    encrypt        = true
  }
}
```

Rules:

- One state key per environment - never share a key across envs.
- Bucket: versioning on, public access blocked, encryption on.
- State files may contain sensitive values - treat the bucket as secret-bearing; never commit `*.tfstate`.

---

## Workspace vs directory-per-env

Default: **directory-per-env**.

```text
infra/
├── modules/
│   ├── network/
│   ├── database/
│   └── service/
└── envs/
    ├── dev/
    ├── staging/
    └── prod/
```

- **Directory-per-env (default):** each env has its own backend key, variables, and blast radius. Preferred - an apply in `dev` cannot touch `prod` state.
- **Workspaces:** acceptable for small teams when envs are structurally identical and differ only in variables. Same state file family - a workspace mixup is a cross-env incident; guard with `-workspace` checks in scripts.

Pick one strategy per repo and record it in an ADR; do not mix.

---

## Module layout conventions

- `modules/<name>/` holds reusable, versioned modules (`main.tf`, `variables.tf`, `outputs.tf`, `README.md`).
- `envs/<env>/` holds thin root configs: backend, provider pins, module calls, env-specific variables.
- No resource blocks directly in `envs/` beyond trivial glue - resources belong in modules.
- Module inputs explicit; no `data "terraform_remote_state"` sprawl across envs without an ADR.

---

## Plan-approval gate checklist

`apply` mode (see `skill.md` § Apply protocol) requires all of:

- [ ] Human-readable plan presented in chat (creates / changes / destroys counts).
- [ ] Every **destroy** or **replace** called out by name.
- [ ] Operator approved the plan in this session (Form B close).
- [ ] Saved plan file matches current config (re-plan is empty).
- [ ] State locking confirmed on.
- [ ] MOD-08 concept prompt attached for first apply to shared infra (`concepts/declarative-infra/prompt.md`).

---

## Drift detection cadence

- **Scheduled:** run `terraform plan -detailed-exitcode` on a schedule (CI cron or ops runbook) per shared env; alert on exit `2`.
- **On incident:** run `drift` mode before any manual console change is accepted as permanent - either import the change into config or revert the drift.
- **Interpretation:** exit `0` = clean, `2` = diff (list resources; propose `plan` for remediation), `1` = error (credentials, state lock, provider - fix the cause, never the state).
- Never auto-`apply` to "fix" drift from a scheduled job - drift remediation is a reviewed plan like any other change.

---

## Secrets handling

- **Never** commit secrets to `.tf`, `*.tfvars`, or state-adjacent files.
- Injection order of preference: secrets manager (AWS Secrets Manager / SSM, Vault) read via `data` sources → `TF_VAR_*` environment variables → `.tfvars` files listed in `.gitignore`.
- Mark sensitive outputs `sensitive = true`; remember they still land in state - protect the backend accordingly.
- `.gitignore` must cover: `*.tfstate*`, `.terraform/`, `*.tfvars` (unless explicitly example files), `crash.log`.

---

## Provider version pinning

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

- Pin every provider in each root config (`envs/<env>/`).
- Commit `.terraform.lock.hcl` - it is the supply-chain record for provider binaries.
- Upgrade providers via a reviewed plan like any other change.

---

## Edge cases

| Situation | Behavior |
|-----------|----------|
| Existing unmanaged infra | Import via `import` blocks (TF 1.5+) or `terraform import` with approval; never hand-edit state |
| State locked by a dead process | Investigate the lock holder; `force-unlock` only with same-message approval |
| Drift caused by console change | Decide: codify (import into config) or revert (apply). Record the decision in an ADR |
| Plan shows unexpected destroys | Stop. Do not apply. Investigate moved/renamed resources first |
| Multiple engineers applying concurrently | Locking serializes applies; still require one approved plan per apply |

---

## Project layout convention

```text
.ai/skills/infra-terraform/
├── skill.md          ← canonical workflow
└── reference.md      ← this file

(Project infra - not in .ai/)
infra/
├── modules/
└── envs/<env>/
```
