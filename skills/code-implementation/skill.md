---
name: code-implementation
description: >-
  Execute an approved implementation iteration: validate or generate the
  NEXT.md iteration block from the plan-master milestone, implement tasks per
  CONVENTIONS and FEATURE_STANDARD, gate each task on tests/lint, and finalize
  the iteration. Verification modes live in the **code-verify** skill. Use when the
  user says code-implementation plan, start, continue (optional - N, until blocked,
  or M{N}-T{a}..T{b}), complete, or status.
  Requires implementation-ready (plan-master Approved) or explicit HANDOFF waiver.
---

# code-implementation

Execute implementation iterations derived from an **Approved master plan** (`{PLANS_ROOT}/full/YYYYMMDD-full-plan.md`). Each iteration is scoped by a `## Current iteration` block in `NEXT.md` - validated before the first line of code, gated per task on tests/lint, and cross-verified before completion.

**Tool-agnostic** (Cursor, Claude Code, opencode, Codex). **Requires:** `implementation-ready: yes` from `@plan-master status`, or an explicit HANDOFF waiver noting which milestones may proceed early.

**Pairs with:** `session-control` (bookends), `plan-master` (milestone source and revisions), `code-verify` (milestone / uncommitted / last audits), `code-repair` (remediate verify/migration failures), `db-migration` (all schema changes), `.ai/standards/*CONVENTIONS*`, `.ai/standards/*FEATURE_STANDARD*` (paths from `.cursorrules`).

**Registry:** [`.ai/skills/SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md).

**Canonical path:** `.ai/skills/code-implementation/skill.md` · **Invocation examples:** `reference.md`

**Hard rules:**

- **No implementation without a valid iteration block.** If `NEXT.md` lacks one, run `plan` first (alias: `plan-iteration`).
- **No code without reading the relevant SPEC(s) first.** Evidence-first: read before writing.
- **No task is `done` until its gate passes.** Tests + lint + type-check must exit 0 before advancing.
- **Scope discipline.** Do not modify any file not declared in the task's file list. Undo and document any accidental out-of-scope change.
- **Schema changes go through `db-migration`.** Stop the task, create the migration script, resume. No inline DDL in application code. Follow `.cursorrules` § **Migration policy** (startup runner, verify, human approval for exceptions/test DML).
- **Verification commands** come from `{AGENT_RULES_FILE}` § Docker (or § local/CI from `REPLACE:TECH_STACK_DOC` when not containerized). Never hardcode another project's service name, workdir, or toolchain.
- **No host dependency installs** for containerized services (`{AGENT_RULES_FILE}` § Host hygiene) — e.g. run `npm ci` via `docker compose exec`, not on the host.
- **Protected files** per `{AGENT_RULES_FILE}` §Protected Files - require explicit user permission before modification. Stop and ask.
- **No secrets in code, tests, or comments.** Use `.env` variables or KMS references.
- **Completion Gate is non-negotiable.** Per `.cursorrules`: code changed → checks run → output reviewed → residual risks listed. Cannot be skipped.
- **AI-assisted default:** Cursor/agent sessions are **AI-assisted: yes** for MOD-06 unless the human explicitly declares **`human-only`** in the same message. Agents must not skip MOD-06 by self-classifying.
- **MOD-06 before complete:** `@concept-run - MOD-06` (or documented output path) is **required** before `@code-implementation complete` when any task in the iteration touched application source or tests (per DIRECTORY_MAP).
- **Every mode ends with a Completion checklist** - each item `pass` | `fail` | `skip` with evidence.

---

## Parse invocation

Normalize the user message to **verb** + optional **target**.

| User says | Verb | Action |
|-----------|------|--------|
| `@code-implementation` **status** | status | Read-only: task matrix, progress snapshot |
| `@code-implementation` **plan** - M1 | plan | Generate/validate `## Current iteration` block from plan-master milestone |
| `code-implementation` **start** | start | Load iteration block, read SPECs/CONVENTIONS, begin first task |
| `code-implementation` **continue** | continue | [Continue protocol](#continue-protocol) - default **1** task (see target table) |
| `code-implementation` **continue** - 5 | continue | Batch: up to **5** tasks, same stop rules as below |
| `code-implementation` **continue** - until blocked | continue | Batch: tasks until gate **fail**, **blocked**, or queue exhausted |
| `code-implementation` **continue** - M4-T2..T6 | continue | Batch: inclusive task **range** in iteration order |
| `code-implementation` **complete** | complete | Finalize iteration: CO2 `@code-verify milestone` + CO1 gates + update HANDOFF/NEXT |
| `code-implementation` **verify** [uncommitted \| last] | - | **Legacy** - use `@code-verify` (see `code-verify` skill) |
| `code-implementation` **task** T3 | task | Execute a single task by shorthand ID (active iteration context) |
| `code-implementation` **task** M1-T3 | task | Execute a single task by globally unique ID; gate immediately |

**Aliases:** `impl`, `code`, `implement` → map to **continue** if iteration block exists, else **start**. **`plan-iteration`** is the legacy alias of **`plan`** - both work.

**Natural language (same semantics):** "implement the next 5 tasks", "continue until blocked/failed" → parse as **`continue - 5`** or **`continue - until blocked`** when the user is clearly invoking this skill.

**Ambiguous:** if `NEXT.md` has an iteration block but status is unknown → run abbreviated **status** and ask once.

**Disambiguation:** On **`continue`**, `- M4` alone is **not** a milestone (use **`plan - M4`**). After `-`, only: a positive integer (`5`), `until blocked`, or a task range (`M4-T2..T6`).

---

## Step 0 - Pick a mode

| Mode | Condition | Action |
|------|-----------|--------|
| **status** | progress/matrix/snapshot requested | [Status protocol](#status-protocol) - read-only |
| **plan** *(alias: `plan-iteration`)* | iteration block missing or invalid; user names a milestone | [Plan protocol](#plan-protocol) |
| **start** | valid iteration block exists; no task started | [Start protocol](#start-protocol) |
| **continue** | iteration in-progress; tasks pending or one in-progress | [Continue protocol](#continue-protocol) |
| **complete** | all tasks done or user signals completion | [Complete protocol](#complete-protocol) |
| **task** | user names `T{N}` or `M{N}-T{N}` | Execute that task; run gate; report |

Do not run `plan` when the user asked for **status** only. For any **verify** request, use **`@code-verify`** (`code-verify` skill).

**Suggested cadence:** `@code-verify uncommitted` before commit · `@code-verify last` after commit/push · `@code-verify milestone` before **complete**.

---

## NEXT.md iteration block format

The `## Current iteration` section is owned by this skill. `session-control` and `plan-foundation` manage other sections; do not delete or rewrite theirs.

**Template + filled example:** `reference.md` § "NEXT.md iteration block - quick template". The template has subsections: header (Milestone ref / Status / Started / Target), **In scope**, **Out of scope (explicit)**, **Tasks** (table: `ID | Description | Files | Status | Notes`), **Acceptance criteria**, **Validation steps** (tests/lint/type/manual), **Owner blockers**, **Cross-LLM verification**, **Done this iteration**, **Concept / NFR registry (this iteration)**.

### Task ID convention

Task IDs use the globally unique **`M{N}-T{N}`** format inherited from the approved plan-master (e.g. `M1-T3`). The shorthand `T{N}` is acceptable within this iteration block and in agent prompts when the active milestone is unambiguous. Always use the full `M{N}-T{N}` form in:

- Cross-milestone references
- HANDOFF and NEXT.md `## Done this iteration` table
- Traceability matrix in the plan-master

### Valid iteration block criteria

An iteration block is **valid** when all of the following are true:

1. Milestone ref present and traces to a task row in the approved plan-master §19.
2. In scope / out of scope sections are explicit (not empty).
3. At least one task row with at least one declared file path.
4. Acceptance criteria section present with at least one item.
5. Validation steps include at least one runnable test command from `{AGENT_RULES_FILE}`.
6. **`### Concept / NFR registry (this iteration)`** subsection is present with one row per architecture concept id **or** explicit `N/A` for each id with reason (if the repository has no concept pack, one row: `N/A - no pack`).

If any criterion fails → iteration block is **invalid** → run **plan** before **start**.

---

## Plan protocol

*(Legacy alias: `plan-iteration`. Both invocations resolve here.)*

Generates or validates the `## Current iteration` block in `NEXT.md` from the next incomplete milestone in the approved plan-master.

### PI1 - Verify prerequisites

Approved plan + HANDOFF waivers; blocked-report on fail: [reference.md § Plan protocol (detailed)](reference.md#plan-protocol-detailed) (PI1).

### Blocked-report shape

Per [SKILL_DEPENDENCIES.md § Blocked report shape](../SKILL_DEPENDENCIES.md#blocked-report-shape).

### PI2 - Select target milestone

First incomplete M{N} or user-specified milestone: [reference.md § Plan protocol (detailed)](reference.md#plan-protocol-detailed) (PI2).

### PI3 - Derive tasks

Copy §19 tasks; file paths; SPEC read; complexity; migration sub-tasks: [reference.md § Plan protocol (detailed)](reference.md#plan-protocol-detailed) (PI3).

### PI4 - Write iteration block

Write `## Current iteration` + Concept/NFR registry: [reference.md § Plan protocol (detailed)](reference.md#plan-protocol-detailed) (PI4).

### PI5 - Plan report

Plan report template: [reference.md § Plan protocol (detailed)](reference.md#plan-protocol-detailed) (PI5).

---

## Start protocol

### ST0 - Implementation gate

HANDOFF waiver or `@plan-master status` **implementation-ready** before code: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (ST0).

### ST1 - Mandatory reads

Six-file read table (NEXT, SPECs, standards, HANDOFF): [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (ST1).

### ST2 - Environment snapshot

Git + compose snapshot: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (ST2).

### ST3 - Assumption ledger

Confirmed / Inference / Unverified labels before first task: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (ST3).

### ST4 - Select first task

Mark first pending task `in-progress`: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (ST4).

### ST5 - Start report

Start report template: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (ST5).

---

## Continue target (parse `-` argument)

Resolve the batch **before** the task loop. Default when `-` is omitted: **`count=1`**.

| User target | Batch mode | Task queue |
|-------------|------------|------------|
| *(omit)* | `count=1` | Next incomplete tasks in iteration table order |
| `- 5` or `- 5 tasks` | `count=5` | Next up to 5 incomplete tasks |
| `- until blocked` | `until-blocked` | Next incomplete tasks until a **stop condition** (below) |
| `- M4-T2..T6` | `range` | Inclusive `M4-T2` … `M4-T6` that exist in the active iteration block, in table order |

**Range rules:**

- Both endpoints must use full `M{N}-T{N}` ids (shorthand `T2..T6` allowed only when the active milestone is unambiguous - expand to `M{N}-T2..M{N}-T6`).
- Skip tasks already `done` (do not count toward work; they are not in the queue).
- If the range includes a `blocked` task that stays blocked after the unblock check → **stop the batch** at that task (do not skip within the range).

**Equivalence:** `@code-implementation continue - 5` means **implement the next 5 incomplete tasks, or fewer if a stop condition fires first** (gate fail, blocker, protected file, schema detour, or queue exhausted). Same as "implement the next 5 tasks or until blocked/failed."

---

## Continue protocol

1. Run [ST0 - Implementation gate](#st0--implementation-gate) (abbreviated if start ran in same session).
2. Parse [Continue target](#continue-target-parse--argument); emit planned queue.
3. **Unblock check** on `blocked` tasks (UNKNOWNS + Owner blockers).
4. Empty queue → recommend **complete** or **status**.
5. **Pre-write scope gate (mandatory — block if undeclared).** Before ANY file write:
   - Check whether `.work/touch-scope` exists with non-empty `allowed_paths` or `allowed_patterns`.
   - Check whether the active `## Current iteration` has at least one task with a populated `Files` column (not empty, not `…`).
   - If **neither** scope declaration exists → **stop the batch** immediately; emit a [scope-undeclared blocked report](#scope-undeclared-blocked-report).
   - If scope IS declared → proceed to the per-task loop.
6. **Per-task loop:** read → implement → [Task gate](#task-gate) → progress line on pass; **stop batch** on fail/blocker/schema/protected-file.
7. **Batch-end sweep** (mandatory when files changed).
8. Emit batch summary with sweep verdict.
9. All tasks `done` → recommend **complete** (do not auto-finalize).

**Batch progress lines, batch summary template, batch-end sweep steps, stop conditions:** [`reference.md` § Continue protocol (detailed)](reference.md#continue-protocol-detailed).

### Scope-undeclared blocked report

```markdown
## @code-implementation continue — blocked (scope undeclared)

**Required:** scope declaration before file writes
**Detected:** no `.work/touch-scope` and no iteration task `Files` column populated
**Run first:** declare scope via one of:
- `.work/touch-scope` JSON: `{"allowed_paths":["path/to/file.md"],"allowed_patterns":[]}`
- Populate the `Files` column in `## Current iteration` task table
Then re-run `@code-implementation continue`.
```


---

## Task gate

Run after every task before marking `done`. All checks must pass. **Mechanical only** — use `@code-verify` for audit reports.

**Check table, manual verify list, SC1 self-critique, post-fix re-gate, scope violation:** [`reference.md` § Task gate (detailed)](reference.md#task-gate-detailed).

### SC1 - Self-critique

Five-prompt table: [reference.md § Task gate (detailed)](reference.md#task-gate-detailed) (SC1).

### Post-fix re-gate

Re-run full task gate after any fix: [reference.md § Task gate (detailed)](reference.md#task-gate-detailed).


## Status protocol

Read-only. No file writes.

1. Read `NEXT.md §Current iteration`; `git diff --stat`; `git log --oneline -5`; count task statuses.
2. Output status report: [reference.md § Status protocol (detailed)](reference.md#status-protocol-detailed).


## Verification (delegated)

All verify modes moved to **`code-verify`** (`.ai/skills/code-verify/skill.md`):

| Mode | When |
|------|------|
| `@code-verify milestone` | Before **complete**, ≥80% tasks, or full iteration audit |
| `@code-verify uncommitted` | Dirty tree, pre-commit |
| `@code-verify last` | After commit or push - audits whichever event was **last** |

Legacy `@code-implementation verify` → run **`@code-verify milestone`**.

---

## Complete protocol

**Execution order:** **CO2 → CO1 → CO3 → CO4 → CO5 → CO6** (milestone verify before final gates - avoids duplicate full-suite runs).

### CO2 - Verify (mandatory before complete)

Run **`@code-verify milestone`** if not run since last task completed. Verdict **pass** or **pass with gaps** required; **fail** blocks completion.

### CO1 - Full iteration gate

Manual validation, Concept/NFR registry, MOD-06 gates; skip duplicate suite when CO2 passed on same tree: [reference.md § Complete protocol (detailed)](reference.md#complete-protocol-detailed) (CO1).

### CO3 - Documentation updates

SPEC amendments, plan/foundation gaps, registry appends: [reference.md § Complete protocol (detailed)](reference.md#complete-protocol-detailed) (CO3).

### CO4 - NEXT.md update

Mark iteration complete; refresh Recommended next: [reference.md § Complete protocol (detailed)](reference.md#complete-protocol-detailed) (CO4).

### CO5 - HANDOFF update

Append artifacts; refresh Repository state: [reference.md § Complete protocol (detailed)](reference.md#complete-protocol-detailed) (CO5).

### CO6 - Close report

Complete report template and checklist: [reference.md § Complete protocol (detailed)](reference.md#complete-protocol-detailed) (CO6).


---

## Blocked task protocol

When a task cannot proceed mid-implementation:

1. Mark task status `blocked` in the iteration block.
2. Record blocker in `### Owner blockers` and in `{PLANS_ROOT}/UNKNOWNS.md` (owner = "human" or named role; `blocks: T{N}`).
3. If the blocker is an ambiguity in SPEC or Full Plan → add to UNKNOWNS; surface in next status report; ask the user once.
4. Move to the next non-blocked pending task (if one exists).
5. If all tasks are blocked → do not hallucinate a resolution. Recommend `@session-control close` with the blockers listed explicitly.
6. Do not invent owner-decision resolutions. Pause and ask.

---

## Integration with other skills

| Skill | Integration |
|-------|-------------|
| `session-control` | Run `@session-control start` before `code-implementation start`; run `@session-control close [commit]` after `code-implementation complete` |
| `plan-master` | Source of milestones; use `@plan-master status` to confirm implementation-ready; `@plan-master revise` if plan gaps surface |
| `code-verify` | **milestone** (CO2) before **complete**; **uncommitted** / **last** optional pre-commit / post-push cadence; task gate runs inline checks - does not delegate to verify |
| `plan-foundation` | Rarely invoked during implementation; only when **milestone** verify surfaces a structural foundation gap |
| `db-migration` | Mandatory for any schema change; stop task, run `@db-migration create`, resume after migration script exists |
| **Concept pack** | Run applicable `prompt.md` during **`@code-verify milestone`**; **MOD-06 required** before **complete** when code changed; attach outputs to PR or `NEXT.md` |

---

## Anti-patterns

*(Behaviors not covered by Hard rules above; Hard rules are not restated here.)*

- Writing code without reading the relevant SPEC(s) first - the read precedes the edit.
- Reporting "tests pass" without running them and reviewing output.
- Skipping the task gate because "it's a small change."
- Skipping **SC1 self-critique** because the task "looked simple".
- Claiming a fix succeeded without **re-gating** the affected task(s).
- Skipping the **Batch-end sweep** at end of `continue` (single-task or batch).
- Proceeding to complete without `@code-verify milestone`.
- Skipping the **Concept / NFR registry** subsection in the active iteration when a concept pack is documented in agent rules.
- Skipping **MOD-06** by self-classifying an agent session as non-AI.
- Passing **Observability** in `@code-verify milestone` without checking SPEC §9 fields on touched code paths.
- Inventing a resolution for an owner-decision blocker.
- Editing merged SPECs or archived decision prompts during implementation.
- Logging PII (emails, tax IDs, amounts) in structured log events.
- Adding attribution comments ("Generated by…", "Created by AI").
- Marking implementation-ready in this skill (that is `@plan-master status`).

---

## Completion checklist (all modes)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected correctly | pass/fail | |
| 2 | NEXT.md iteration block valid | pass/fail | criteria |
| 3 | SPEC(s) read before implementation | pass/skip | paths |
| 4 | CONVENTIONS + FEATURE_STANDARD read | pass/skip | |
| 5 | Task gate passed per task | pass/fail | exit codes |
| 5b | SC1 self-critique recorded per task | pass/fail | bullets in Notes |
| 5c | Post-fix re-gate executed (if any fix applied) | pass/skip | task ids re-gated |
| 6 | No out-of-scope files modified | pass/fail | git diff |
| 7 | No secrets in output | pass/fail | |
| 8 | Schema changes via db-migration | pass/skip | |
| 8b | Batch-end sweep run (continue mode) | pass/fail/skip | sweep verdict |
| 9 | `@code-verify milestone` (complete mode) | pass/skip | verdict |
| 10 | NEXT.md + HANDOFF updated (complete mode) | pass/skip | |
