---
name: session-control
description: >-
  Open or close an AI working session with verified context load, HANDOFF and NEXT
  updates, and optional git commit/push with repo-mode-dependent scope: the whole
  repo in the Agent OS framework source repo, or the `.work/` working directory
  plus root-level general files (PROCESS_ROUTER.md, DOCS_TECH_STACK.md,
  CHANGELOG.md — if present) in consumer repos. Also supports standalone
  commit/push without closing (commit task ref, git add
  + git commit + git push, no HANDOFF/NEXT update). `context` loads all mandatory
  context read-only and is uncommitted-aware (surfaces dirty-tree status without
  writing HANDOFF). Use when the user says session-control start, session-control
  close, @session-control start, close commit, close commit push, commit, commit
  push, or session-control context. Never commits unless the invocation includes
  commit. On commit, MUST run git add + git commit in the shell for all safe
  in-scope changes per repo mode — including new untracked files/dirs (not
  HANDOFF-only).
---

# session-control

Bookend AI work sessions so the next chat (or human) can resume without guessing. **Tool-agnostic**; **project-agnostic** when `{HANDOFF}` exists.

**Pairs with:** `.cursorrules`, `plan-foundation` skill (optional status on start/close), `{ITERATION_CARRIER}`.

**Registry:** [`.ai/skills/SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md).

**Canonical path:** `.ai/skills/session-control/skill.md` · **Invocation examples:** `reference.md`

**Hard rules:**

- **Default close / default commit:** never `git commit` or `git push`. Only when invocation includes **`commit`** and/or **`push`** (see [Parse invocation](#parse-invocation)).
- **`close commit` / `close commit push` / `commit` / `commit push`:** **MUST** run `git add` + `git commit` in the shell (see [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C4b) / [Commit protocol](#commit-protocol)), staging per **repo mode** (see [Parse invocation](#parse-invocation) § Commit scope): **whole repo** in the Agent OS framework source repo, **`.work/` + general root files** in consumer repos (both incl. new untracked files/dirs). A dirty in-scope tree after close with only a draft message is **fail**.
- **Always** show the commit message - drafted, used for commit, or `none - working tree clean`.
- **`commit` / `commit push` (standalone):** run git add + commit + push **without** updating HANDOFF or NEXT. Session stays open. Useful for mid-session checkpoints.
- **Never commit with `type:` format when a task ref is known or could reasonably be asked for.** If the user provided a ref, or the branch/HANDOFF/github-registry contains one — use it. If no ref is known but the work clearly belongs to a task, ask the user once. Commits without refs are not linked to tasks/tickets and are invisible in the association UI.
- Never edit files marked **archived** or **do not edit** in HANDOFF.
- Never paste secrets from `.env`, `credentials/`, or tokens into chat or HANDOFF.
- **`{PROMPTS_ROOT}/initial.md` is user-owned.** Do not read or create it on start/close unless the user explicitly names that path in the same invocation.
- Every mode ends with a **Completion checklist** - each item `pass` | `fail` | `skip` with evidence.
- **Operator handoff:** every response that ends a turn follows the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — terse output; approvals under `**Needs your approval:**` citing `path:L<n>`; questions numbered under `**Needs your answer:**`; exactly one `**Next step:**` command; one line when nothing is needed (Form A). Decisions and questions never mixed; empty sections omitted.

### Path resolution (mandatory before any Read)

Resolve from **repository root** (see [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) § Work tree path resolution). `{WORK_ROOT}` = **`.work/`** — not the repo root.

| Artifact | Read / write this path |
|----------|-------------------------|
| `{HANDOFF}` | `.work/context/HANDOFF.md` |
| `{ITERATION_CARRIER}` | `.work/plans/NEXT.md` |
| `{PLANS_ROOT}/UNKNOWNS.md` | `.work/plans/UNKNOWNS.md` |

**Never** open `context/HANDOFF.md`, `plans/NEXT.md`, or bare `HANDOFF.md` / `NEXT.md` at repo root — those paths are wrong for Agent OS.

---

## Parse invocation

Normalize the user message to **verb** + optional **modifiers**. The word `session` is **optional** (legacy alias).

| User says | Verb | Git action |
|-----------|------|------------|
| `@session-control` **start** | start | - |
| `session-control` **start** - \<goal\> | start | - |
| `@session-control` **close** | close | draft message only |
| `session-control` **close** | close | draft message only |
| `session-control` **close** **commit** | close | commit all **safe** in-scope changes per repo mode (default scope - [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C4b)) |
| `session-control` **close** **commit** **scoped** | close | commit only HANDOFF + NEXT + paths listed in close report |
| `session-control` **close** **commit** **push** | close | commit then push |
| `session-control` **close** **push** | close | treat as **commit push** (`push` requires commit) |
| `session-control` **commit** | commit | commit all safe in-scope changes per repo mode (default scope), NO close |
| `session-control` **commit** **push** | commit | commit then push, NO close |
| `@session-control` **context** | context | - |
| `@session-control` **status** | status | - |

**Aliases (same verb):** `begin`, `open` → start; `end`, `handoff` → close.

**Goal text:** anything after `-` or on a new line after `start` (not the words `commit`/`push`/`scoped`).

**Commit scope (repo-mode dependent):** detect mode first — **framework source repo** ⇔ repo root contains `agent.os.framework.md` (the framework source marker; never modified, never deployed); anything else is a **consumer repo** (fat or thin client).

| Mode | Default commit scope (`commit` / `close commit`) |
|------|--------------------------------------------------|
| Framework source | **Whole repo** — all safe changed + **new untracked files/dirs** (e.g. `git add -A`, minus the exclusions below) |
| Consumer | **`.work/`** plus root-level `PROCESS_ROUTER.md`, `DOCS_TECH_STACK.md`, `CHANGELOG.md` **if present** (e.g. `git add .work/ PROCESS_ROUTER.md DOCS_TECH_STACK.md CHANGELOG.md`, tolerating missing files) |

Exclusions in both modes: secrets-scan paths (C1), `tmp/`, `.obfuscation/output/`, and protected files per §Protected Files — never staged by session commits; list them in the close/commit report as follow-ups. Note **`push` ships the whole branch** — scope only controls what enters the new commit. Use **`commit scoped`** only when the user wants bookend files (HANDOFF + NEXT) only.

**Standalone commit:** `commit` / `commit push` run the same git steps as `close commit` / `close commit push` but **skip** HANDOFF and NEXT updates. The session remains open.

---

## Step 0 - Pick a mode

| Mode | Triggers | Action |
|------|----------|--------|
| **start** | `start`, optional goal | [Start protocol](#start-protocol) |
| **close** | `close` [commit] [push] | [Close protocol](#close-protocol) |
| **commit** | `commit` [push] | [Commit protocol](#commit-protocol) - git only; no HANDOFF/NEXT writes |
| **context** | `context` | [Context protocol](#context-protocol) - full mandatory context load + uncommitted-aware summary; no HANDOFF writes |
| **status** | `status` | [Status protocol](#status-protocol) - compact snapshot; no HANDOFF writes |

If the user gives a **task goal** with start (e.g. `start - work on payments SPEC`), capture it in the start report and use HANDOFF's conditional reading table.

---

## Start protocol

### S1 - Baseline reads (mandatory)

Five-file read table (.cursorrules, HANDOFF, NEXT, UNKNOWNS, optional doc 01): [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S1).

### S1b - Unblock check (when `.work/plans/NEXT.md` has an active iteration)

Scan `blocked` tasks; flip to `pending` when resolved: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S1b).

### S2 - Conditional reads (task-based)

Task-based conditional read table: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S2).

### S3 - Environment snapshot (evidence)

Git snapshot + optional compose ps: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S3).

### S3c - MCP availability (informational, non-blocking)

Optional MCP detection note for start report: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S3c).

### S4 - Session goal (interaction)

Capture goal; ask once if unclear: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S4).

### S4b - Coding goal readiness (when goal implies implementation)

Implementation-ready check before coding: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S4b).

### S4c - Task registry lookup (mandatory, no-network)

Read `.github/task-registry.json`; match ref; write `.work/active-ref`: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S4c).

### S5 - Mark session open (HANDOFF)

Update `## Session status` Open line only: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S5).

### S6 - Start report (mandatory output)

Start report template and checklist: [reference.md § Start protocol (detailed)](reference.md#start-protocol-detailed) (S6).


---

## Status protocol

Read-only snapshot. **No** HANDOFF/NEXT writes. **No** completion checklist.

1. Read `.work/context/HANDOFF.md` and `.work/plans/NEXT.md`.
2. Run `git status -sb` and `git log -1 --oneline`.
3. Output:

```markdown
## Session status - <Project>

**Session:** Open | Closed - <date> - <goal if Open>
**Branch:** <branch> · **Tree:** clean | dirty
**Pick up:** <one line from NEXT.md>
**Owner blockers:** <short list or none>
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [SKILL_DEPENDENCIES.md](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

Optional: one line on dirty files (no full diff). For full context load, use **start**.

For full context load **without** HANDOFF writes + uncommitted-aware detail, use **context**.

---

## Context protocol

Read-only full context load. **No** HANDOFF/NEXT/active-ref writes. **No** completion checklist (it is read-only, like `status`); end with the context report. Sits between `status` (one-line compact) and `start` (full load + marks HANDOFF Open).

Difference from `start`: writes nothing. Difference from `status`: loads the **full mandatory context set** (S1) plus a dirty-tree **diff summary**, not just a one-liner.

Use when: an operator (or agent) wants full session context for ad-hoc reasoning without opening/closing a session bookend — e.g. mid-session orientation, a second agent joining, debugging "what changed and what's next" without mutating HANDOFF.

### X1 - Mandatory context reads (read in full)

Same set as [S1](reference.md#s1-baseline-reads-mandatory):

| # | File (repo-root path) | Pass criteria |
|---|----------------------|----------------|
| 1 | `.cursorrules` | identity, 7 core principles, protected files, no-commit rule |
| 2 | `.work/context/HANDOFF.md` | §Session status → §Open owner actions |
| 3 | `.work/plans/NEXT.md` | Recommended next + owner blockers |
| 4 | `.work/plans/UNKNOWNS.md` | every open unknown + owner + Blocks |
| 5 | `.work/plans/foundation/*-01-*-initial-scope.md` **if present** | one-sentence product intent (or skip) |

Conditional reads per [S2](reference.md#s2-conditional-reads-task-based) only when the operator named a domain.

### X2 - Uncommitted-aware snapshot (evidence)

Run:

```bash
git status -sb
git diff --stat
git diff --cached --stat
git log -1 --oneline
```

Classify the working tree:
- **clean:** state explicitly; report last commit only.
- **dirty:** summarize by top-level area (e.g. `3 files .ai/skills/`, `1 file .work/plans/`); list staged vs unstaged vs untracked counts. **Do not** paste full diffs — file paths + per-area counts only (per `.cursorrules` no-PII/scope discipline). Flag any path matching secrets scan patterns ([reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) C1) without printing content.

### X3 - Context report (mandatory output)

```markdown
## Session context - <Project Name>

**Date:** <ISO date> · **Branch:** <branch> · **Working tree:** clean | dirty (N files)
**Last commit:** <sha - subject>

### Context loaded
| # | File | Result | Note |
|---|------|--------|------|
| 1 | .cursorrules | pass | |
| 2 | .work/context/HANDOFF.md | pass (or missing) | §Session status: Open|Closed … |
| 3 | .work/plans/NEXT.md | pass (or missing) | |
| 4 | .work/plans/UNKNOWNS.md | pass (or missing) | |
| 5 | P0 initial scope | pass|skip | |

### Uncommitted status (read-only)
- Staged: <N files> · Unstaged: <N files> · Untracked: <N files>
- Areas touched: <top-level dirs with counts>
- Secrets scan: clean | <flagged paths (not printed)>
- (Clean tree → omit this section; state "working tree clean".)

### Pick up here
<quote recommended next from NEXT.md, or "no NEXT.md" >

### Open blockers (owner)
<from HANDOFF / NEXT, or none>

### No files written
This mode is read-only: HANDOFF, NEXT, UNKNOWNS, and `.work/active-ref` are **not** modified. To open a session bookend, run `@session-control start`.
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [SKILL_DEPENDENCIES.md](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

### Anti-patterns (context)
- Treating `context` as `start` (writing the HANDOFF "Open" line) — `context` writes nothing.
- Pasting raw `git diff` output (use per-area counts; respect no-PII/scope).
- Skipping the secrets-flag pass on a dirty tree.
- Claiming "context loaded" without reading all of S1 set every time the verb runs.

---

## Commit protocol

**Execution order:** M1 → M2 → M3 → M4 (draft message with task ref) → M5 (git, if `commit`/`push`) → M6 (report).

Runs git commit and optional push **without** updating HANDOFF or NEXT. Session remains open. Idempotent — re-runnable mid-session.

If M1 secrets **fail**, **stop** — do not run M4 or M5.

### M1 - Working tree audit (same as C1)

Same as [C1 in reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed).

### M2 - Verification gate (same as C2)

Same as [C2 in reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed).

### M3 - Follow-ups

Same as [C3 in reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed).

### M4 - Commit message with task ref (always)

Always produce the commit message block — even when tree is clean. Task ref extraction, subject/body format, and report labels: [reference.md § Commit protocol (detailed)](reference.md#commit-protocol-detailed) (M4).

### M5 - Git actions (modifiers only)

Same as [C4b in reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed). **Hard rules:** agents MUST run shell git; no `Co-authored-by:` trailers.

### M6 - Commit report (mandatory output)

Report template and checklist: [reference.md § Commit protocol (detailed)](reference.md#commit-protocol-detailed) (M6).

---

## Close protocol

**Execution order:** C1 → C2 → C3 → C4 (draft message) → C5 (HANDOFF) → C6 (NEXT) → C4b (git, if `commit`/`push`) → C7 (optional) → C8 (report).

If C1 secrets **fail**, **stop** - do not run C5, C6, or C4b; report failure in C8.

### C1 - Working tree audit (mandatory)

`git status` + diff stats; classify findings; **secrets scan** (halt close on match). Full table and patterns: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C1).

### C2 - Verification gate (this session)

Completion Gate honesty table; optional probe/traceability pre-checks. Details: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C2).

### C3 - Follow-ups required

Detect uncommitted work, stale HANDOFF/NEXT, ADRs, owner actions, temp files, SPECs. Checklist: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C3).

### C4 - Commit message with task ref (always)

Always show commit message in close report. Task ref priority order and format: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C4).

### C4b - Git actions (modifiers only)

Modifier table, **default commit scope**, HEREDOC commit shape, post-commit verification. Full spec: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C4b).

### C5 - Update HANDOFF (mandatory on close)

Nine-section rewrite list + `.work/active-ref` cleanup: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C5).

### C6 - Update NEXT.md (mandatory on close)

Done / Recommended next / Blocked refresh: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C6).

### C7 - Optional: plan-foundation status

Optional ≤5-line foundation status on close: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C7).

### C8 - Close report (mandatory output)

Close report template and checklist: [reference.md § Close protocol (detailed)](reference.md#close-protocol-detailed) (C8).

---

## Critical interactions

| When | Ask / do |
|------|----------|
| **Start** | Prior HANDOFF says `Closed` → treat as new session; do not assume prior chat memory |
| **Start** | Missing HANDOFF → offer to run `plan-foundation` greenfield or create minimal HANDOFF |
| **Close** | `close commit` / `close commit push` → run C4b in shell after HANDOFF/NEXT; stage per **repo-mode scope** (whole repo in framework source; `.work/` + general root files in consumers) |
| **Commit** | User says `@session-control commit` → Run [Commit protocol](#commit-protocol); **do not** update HANDOFF or NEXT |

Full table: [reference.md § Critical interactions](reference.md#critical-interactions).

---

## Anti-patterns

- Claiming "context loaded" without reading HANDOFF and NEXT
- Closing session without updating HANDOFF and NEXT (on **close**)
- **`close commit` without running `git commit`** or without a new SHA
- **Staging outside the repo-mode scope** on a default commit — in a consumer repo, session commits touch `.work/` + the general root files only (`.ai/`, app dirs stay out); the whole-repo scope applies **only** in the framework source repo
- Omitting the commit message block from close/commit reports
- Adding `Co-authored-by:` trailers
- Burying operator actions/questions in prose instead of the closing handoff block (Form A single line / Form B labeled sections)

Full list: [reference.md § Anti-patterns](reference.md#anti-patterns).

---

## Project layout (convention)

**`{WORK_ROOT}` = `.work/`** at repo root. See [reference.md § Project layout](reference.md#project-layout-convention). Session git commit scope is **repo-mode dependent** (see [Parse invocation](#parse-invocation) § Commit scope): whole repo in the framework source repo; `.work/` + general root files in consumers.
