---
name: infra-terraform
description: >-
  Manage Terraform infrastructure across the init/plan/apply/drift/destroy
  lifecycle with approval gates. Remote state with locking for shared
  environments, human-readable plans as the review artifact, apply only against
  an approved plan, read-only drift detection, and a hard-stop destroy mode.
  Use when the user asks to write, change, plan, apply, or destroy Terraform /
  IaC, set up state backends, or check infra drift.
---

# infra-terraform

Manage **Terraform** infrastructure with **state as the source of truth** and **plan review as the gate** before any change to shared environments.

**Tool-agnostic** (Cursor, Claude Code, opencode, Codex). **Cloud-agnostic** at the concept level; backend examples target S3 + DynamoDB and Terraform Cloud.

**Pairs with:** `standards/20260819-IAC_CONVENTIONS.md` (binding standard), `concepts/declarative-infra/` (MOD-08), `.cursorrules` Core Principle 8.

**Canonical path:** `.ai/skills/infra-terraform/skill.md` · **Invocation examples, backend templates:** `reference.md`

**Hard rules:**

- **Plan is the review artifact.** Every `apply` on a shared environment is preceded by a human-reviewed, human-readable plan (`terraform plan -out`). No reviewed plan, no apply.
- **Remote state for shared environments.** Local state is dev-only. Shared envs use a remote backend with **state locking on** (S3 + DynamoDB, Terraform Cloud). See `reference.md` § State backends.
- **Destroy is a HARD STOP.** Never run `terraform destroy` without explicit human approval in the **same message** (`.cursorrules` Core Principle 8). Never wire destroy into CI as a default step.
- **No secrets in code.** Never commit secrets to `.tf`, `*.tfvars`, or state-adjacent files. Secrets come from env vars (`TF_VAR_*`) or a secrets manager. See `reference.md` § Secrets handling.
- **Pin providers.** `required_providers` with version constraints + committed `.terraform.lock.hcl`. See `reference.md` § Provider version pinning.
- **Never edit state by hand.** `terraform state mv/rm` only with explicit approval and a recorded reason; never edit state files directly.
- **Drift is checked, not assumed.** `status`/`drift` modes are read-only (`terraform plan -detailed-exitcode`); report interpretation, never auto-remediate.
- **Operator handoff:** every response that ends a turn follows the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — terse output; approvals under `**Needs your approval:**` citing `path:L<n>`; questions numbered under `**Needs your answer:**`; exactly one `**Next step:**` command; one line when nothing is needed (Form A). Decisions and questions never mixed; empty sections omitted.

---

## Parse invocation

Normalize the user message to **verb** + optional **target** (env, module, workspace).

| User says | Verb | Action |
|-----------|------|--------|
| `@infra-terraform` **init** | init | Backend + remote state + locking setup guidance |
| `@infra-terraform` **setup** | init (alias) | Same as init |
| `@infra-terraform` **plan** | plan | Produce a human-readable plan (the review artifact) |
| `@infra-terraform` **apply** | apply | Apply an approved plan (state locking on) |
| `@infra-terraform` **status** | status | Read-only: state, backend, and drift summary |
| `@infra-terraform` **drift** | drift | Read-only: `terraform plan -detailed-exitcode` interpretation |
| `@infra-terraform` **destroy** | destroy | HARD STOP - same-message human approval required |

**Aliases:** `setup`, `bootstrap` → init. `status` and `drift` are both read-only.

---

## Step 0 - Pick a mode

| Mode | Action |
|------|--------|
| **init** | [Init protocol](#init-protocol) - backend, remote state, locking, layout |
| **plan** | [Plan protocol](#plan-protocol) - produce the review artifact |
| **apply** | [Apply protocol](#apply-protocol) - gated on an approved plan |
| **status** | [Status / drift protocol](#status-drift-protocol) - read-only |
| **drift** | [Status / drift protocol](#status-drift-protocol) - read-only |
| **destroy** | [Destroy protocol](#destroy-protocol) - HARD STOP |

---

## Prerequisite gate (mutating modes)

**Applies to:** `apply`, `destroy`. Skipped for `init` (it builds the prerequisites) and `plan` / `status` / `drift` (read-only on infra).

Before mutating a shared environment:

1. Confirm the backend is remote with locking (check `backend` block or `terraform backend` config).
2. Confirm provider pins: `required_providers` + committed `.terraform.lock.hcl`.
3. If either is missing → **stop** with the [blocked-report shape](#blocked-report-shape):
   - **Required:** remote backend with locking + pinned providers (per `standards/20260819-IAC_CONVENTIONS.md`)
   - **Detected:** local state backend **and/or** unpinned providers
   - **Run first:** `@infra-terraform init`

### Blocked-report shape

Per [SKILL_DEPENDENCIES.md § Blocked report shape](../SKILL_DEPENDENCIES.md#blocked-report-shape) - header: `## @infra-terraform <command> - blocked (prerequisite)`.

---

## Init protocol

Set up backend, state, and layout. Writes `.tf` config only; never applies.

1. **Inventory:** existing `*.tf`, backend config, state files (`*.tfstate`), workspaces.
2. **Choose backend** per `reference.md` § State backends: S3 + DynamoDB locking (AWS), Terraform Cloud, or local (dev-only, never shared).
3. **Choose env strategy** per `reference.md` § Workspace vs directory-per-env: default **directory-per-env** (`envs/dev/`, `envs/staging/`, `envs/prod/` + `modules/`).
4. **Write** the `terraform { backend … required_providers … }` blocks; pin providers.
5. **Never run `terraform init -migrate-state`** against existing state without explicit same-message approval.
6. Output an init report (actions table + remaining manual steps: create the state bucket/table, set credentials via env).

End the report with the Operator handoff close (Form A or Form B) per SKILL_DEPENDENCIES.md.

---

## Plan protocol

Read-only against infrastructure (refreshes state, changes nothing).

1. `terraform init` (if needed) + `terraform validate` + `terraform fmt -check`.
2. `terraform plan -out=tfplan-<env>` and produce the **human-readable** rendering alongside it.
3. Present the plan as the review artifact: creates / changes / destroys counts, and **every destroy or replace called out explicitly**.
4. Blast-radius note per MOD-08 (`concepts/declarative-infra/prompt.md`): which shared resources does this plan touch?
5. Do **not** apply in this mode. Hand the plan to the operator for approval.

End the report with the Operator handoff close (Form B - plan approval is a `**Needs your approval:**` item) per SKILL_DEPENDENCIES.md.

---

## Apply protocol

**Gate:** requires a plan reviewed and approved by the human in this session (see `reference.md` § Plan-approval gate checklist).

1. Confirm the approved plan file matches the current config (`terraform plan` again must be empty against the approved plan, or re-plan).
2. Confirm state locking is active.
3. `terraform apply tfplan-<env>` (apply the saved plan, not a fresh auto-approve run). Never `-auto-approve` on shared envs.
4. Report applied changes + outputs.

End the report with the Operator handoff close (Form A or Form B) per SKILL_DEPENDENCIES.md.

---

## Status / drift protocol

Read-only. No writes to config, state, or infrastructure.

1. Report backend type, workspace/dir, provider pins.
2. Run `terraform plan -detailed-exitcode`: exit `0` = no drift, `2` = drift present (list the diff summary), `1` = error (report, do not remediate).
3. Interpret drift per `reference.md` § Drift detection cadence; propose `@infra-terraform plan` if remediation is wanted - never auto-fix.

End the report with the Operator handoff close (Form A or Form B) per SKILL_DEPENDENCIES.md.

---

## Destroy protocol

**HARD STOP.** `.cursorrules` Core Principle 8 applies.

1. **Stop** and ask for explicit approval in the same message, naming the exact env/workspace and the resources `terraform plan -destroy` reports.
2. Never run destroy in CI as a default step; a CI destroy job requires its own explicit approval each time.
3. On approval: run `terraform plan -destroy` first, show the full destroy list, then `terraform destroy` (still with locking on).
4. Record what was destroyed in the report.

The approval request must be an enumerated `**Needs your approval:**` item in the Operator handoff close (Form B) per SKILL_DEPENDENCIES.md.

---

## Anti-patterns

- Applying without a reviewed, human-readable plan.
- Local state for shared environments (state file on one laptop = unrecoverable drift).
- `terraform destroy` in CI without explicit per-run approval.
- Storing secrets in `.tf` / `*.tfvars` plaintext or committing state files with sensitive outputs.
- Editing state by hand (`*.tfstate` edits, unapproved `state mv/rm`).
- `-auto-approve` on shared environments.
- Unpinned providers or uncommitted `.terraform.lock.hcl`.
- Burying operator actions or questions in prose instead of the closing handoff block (Operator handoff contract, Form A/B).

---

## Integration with other skills

| Skill | Integration |
|-------|-------------|
| `concept-run` | MOD-08 (`declarative-infra`) runs before the first apply to shared infra |
| `plan-foundation` | P5 infrastructure decisions reference `standards/20260819-IAC_CONVENTIONS.md` |
| `dev-stack` | Local containers stay in compose; Terraform owns cloud/shared resources |

---

## Completion checklist (all modes)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected correctly | pass/fail | |
| 2 | Remote backend + locking confirmed (mutating modes) | pass/skip | backend block |
| 3 | Providers pinned, lock file committed | pass/fail | `required_providers` |
| 4 | Plan reviewed and approved (apply mode) | pass/skip | plan artifact |
| 5 | No secrets in config/tfvars | pass/fail | |
| 6 | Destroy approved in the same message (destroy mode) | pass/skip | |
| 7 | Drift exit code interpreted (status/drift mode) | pass/skip | `-detailed-exitcode` output |

Close every mode's final output with the Operator handoff close (Form A or Form B) per SKILL_DEPENDENCIES.md; no operator-required action may live only in a checklist row.
