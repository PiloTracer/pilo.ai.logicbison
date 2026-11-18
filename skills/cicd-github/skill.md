---
name: cicd-github
description: >-
  Install and verify GitHub Actions workflows that run Agent OS gate scripts
  (framework-verify, skill-functional-verify, gate-verify). Use when the user
  wants CI/CD, GitHub Actions, PR checks, or pipeline gates tied to the framework.
---

# cicd-github

Wire **GitHub Actions** to existing Agent OS scripts — no duplicate gate logic in YAML.

**Pairs with:** `standards/20261117-CICD_CONVENTIONS.md`, `scripts/gate-verify.sh`, `scripts/framework-verify.sh`.

**Canonical path:** `skills/cicd-github/skill.md` · **Templates:** `templates/ci/github-actions/`

**Hard rules:**

- Workflows **call** checked-in `scripts/*` — do not embed ad-hoc test commands that bypass `.cursorrules` Completion Gate.
- **`framework-verify`** on framework source repos; on thin-client consumers run app test/lint/type from `.cursorrules` plus optional `gate-verify` on `NEXT.md`.
- **Operator handoff:** follow [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## Parse invocation

| User says | Mode |
|-----------|------|
| `@cicd-github` **install** | Copy workflow template to `.github/workflows/` (no overwrite without approval) |
| `@cicd-github` **status** | Read-only: workflows present, suggested commands |
| `@cicd-github` **verify** | Dry-run: list commands the workflow would run |

---

## Install protocol

1. Ensure `.github/workflows/` exists.
2. Source: `templates/ci/github-actions/framework-gates.yml` (from `$AGENT_OS_SOURCE` when thin-client).
3. If `framework-gates.yml` already exists → **stop**; offer merge or `overwrite` with explicit approval.
4. Report path installed + remind: thin-client repos may need a workflow that invokes consumer test commands from `.cursorrules` in addition to `gate-verify`.

**Next step:** push branch and confirm checks on GitHub.

---

## Status protocol

| Check | pass criteria |
|-------|----------------|
| Workflow file | `.github/workflows/framework-gates.yml` or project-specific variant exists |
| gate-verify | `scripts/gate-verify.sh` reachable (source or consumer) |
| Standard | `standards/20261117-CICD_CONVENTIONS.md` referenced in HANDOFF or DOCS_TECH_STACK optional |

End with Operator handoff Form A or B per contract.

---

## Verify protocol

Read-only. Do not copy or edit workflows.

1. Resolve the workflow the same way as install (`templates/ci/github-actions/framework-gates.yml`, or `.github/workflows/framework-gates.yml` when already installed).
2. List each `run:` command in order.
3. Say whether `scripts/framework-verify.sh`, `scripts/skill-functional-verify.py`, and `scripts/gate-verify.sh` exist beside the workflow or only under `$AGENT_OS_SOURCE`.
4. Do not execute the gates. Execution is `status` plus a local `bash scripts/framework-verify.sh` when the operator asks.

End with Operator handoff Form A or B per contract.