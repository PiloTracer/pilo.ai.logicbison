# session-control - reference

Supplement to `skill.md`. Invocation examples, HANDOFF templates, and edge cases.

---

## Invocation examples

**Canonical forms** - do not require the word `session`:

| Action | Prompt |
|--------|--------|
| Open | `@session-control` **start** |
| Open + goal | `session-control` **start** - bootstrap platform skeleton |
| Close | `@session-control` **close** |
| Close + commit (all safe `.work/` changes incl. new files) | `session-control` **close** **commit** |
| Close + commit (HANDOFF/NEXT only) | `session-control` **close** **commit** **scoped** |
| Close + commit + push | `session-control` **close** **commit** **push** |
| **Commit only (no close)** | `@session-control` **commit** |
| **Commit + push (no close)** | `session-control` **commit** **push** |
| **Full context load (no writes, uncommitted-aware)** | `@session-control` **context** |
| Load check | `@session-control` **status** |

Legacy aliases still work: `session start`, `session close`, `handoff`, `begin`, `end`.

Prior Cursor skill ids (treat as equivalent prompts): `@session-manager` → **session-control**; `@foundation-plan` → **plan-foundation**; `@full-plan` → **plan-master**; `@implement-code` → **code-implementation**; `@sql-migrations` → **db-migration**.

### Cursor

```
@session-control start
@session-control close
@session-control close commit
@session-control close commit push
@session-control commit
@session-control commit push
@session-control context
```

### Claude Code / opencode / Codex

```
Follow .ai/skills/session-control/skill.md - start.
```

```
Follow .ai/skills/session-control/skill.md - close commit push.
```

### Close modifiers (git)

| Invocation | Commit? | Push? | Commit message in report | Closes session? |
|------------|---------|-------|---------------------------|-----------------|
| `close` | no | no | **always** (draft) | yes |
| `close commit` | yes | no | **always** (used + SHA if ok) | yes |
| `close commit push` | yes | yes | **always** (used + push result) | yes |
| `close push` | yes | yes | same as `close commit push` | yes |
| `commit` | yes | no | **always** (used + SHA if ok) | **no** |
| `commit push` | yes | yes | **always** (used + push result) | **no** |

Default `close` never runs `git commit` or `git push`. User runs git manually from the drafted message if they want.

### GitHub task registry (optional)

If the project has `github_task_registry_enabled`, the app maintains a lightweight registry
file (`.github/task-registry.json`) via the GitHub Contents API. Whenever a task or ticket is
created/updated/deleted, the registry is synced to the linked GitHub repo.

Ref allocation (`auto_prefix_enabled`) is **independent** — it controls whether new tasks/tickets
get automatic refs. Both flags are listed in the readiness checklist; you need both enabled plus
a linked repo for the full end-to-end flow.

The AI SHOULD query the registry to discover the correct task/ticket ref:

```bash
curl -s -H "Authorization: Bearer <JWT>" \
  "${API_BASE_URL:-http://localhost:8300}/v1/projects/{project_id}/github/task-registry"
```

Response format:
```json
{
  "version": 1,
  "updated_at": "2026-06-25T12:00:00Z",
  "tasks": [
    {"ref": "PROJ-456", "title": "Add login form", "status": "todo", "project_id": "..."}
  ],
  "tickets": [
    {"ref": "PROJ-T-23", "title": "Login broken", "status": "open", "project_id": "..."}
  ]
}
```

If the registry is unreachable or no match is found, fall back to HANDOFF/branch/last-commit.
**Never block** — the system works seamlessly without the registry.

**Inbound auto-linking (closes the loop):** when commits are synced from GitHub (manual sync,
background poll, or `/sync-backfill`), the app scans each commit message for `[A-Z]+-(?:T-)?\d+`
refs (e.g. `PROJ-456:` / `PROJ-T-23:`), resolves them to task/ticket rows in the same project,
and writes idempotent `commit_subject_refs` rows. So a commit authored with the ref prefix above
is automatically linked back to its task/ticket — no manual step required. Re-syncs never
duplicate rows (`ON CONFLICT DO NOTHING`); linking failures never break the sync.

**`close commit` / `commit` default scope (repo-mode dependent):** first detect mode — **framework source repo** ⇔ repo root contains `agent.os.framework.md` (the framework source marker); anything else is a **consumer repo**. Framework source: stage all **safe** changes in the **whole repo** from `git status --porcelain` (e.g. `git add -A` minus exclusions), **including new untracked files/dirs**. Consumer: stage all safe changes under **`.work/`** (e.g. `git add .work/`) **plus** root-level `PROCESS_ROUTER.md`, `DOCS_TECH_STACK.md`, `CHANGELOG.md` **if present**. Either way: **not** HANDOFF/NEXT only; secrets/`tmp/`/protected files never staged. Agent **must** run shell `git add` + `git commit` and show SHA + post-commit `git status -sb`. See `skill.md` § C4b.

**Standalone `commit` / `commit push`:** same git behavior as `close commit` / `close commit push` but **skips** HANDOFF and NEXT updates. Session stays open.

### Natural language triggers

| Phrase | Maps to |
|--------|---------|
| `start` / `begin` / `open` | start |
| `close` / `end` / `handoff` | close |
| `close commit` | close + commit |
| `close commit push` | close + commit + push |
| `commit` | commit only (no close) |
| `commit push` | commit + push, no close |
| `status` / am I loaded | status |

### Examples

**Start:**

```
@session-control start - implement platform health route
```

**Close (default - no git write):**

```
@session-control close
```

Expect: HANDOFF/NEXT updated; **Commit message** section with draft text; checklist item 6–7 `skip`.

**Close with commit:**

```
session-control close commit
```

Expect: HANDOFF/NEXT updated; agent runs `git add` for the **repo-mode scope** (whole repo in framework source; `.work/` + general root files in consumers; incl. new untracked files/dirs) + `git commit`; report shows SHA and `git status -sb` (clean or explicit leftovers). **Fail** if only bookend files were committed while other safe in-scope changes remain unstaged, or if out-of-scope files were staged.

**Close with commit and push:**

```
session-control close commit push
```

Expect: commit then `git push -u` if needed; report shows push result or error.

**Commit only (no close):**

```
session-control commit
```

Expect: git audit, task ref auto-detected from HANDOFF or branch, commit message drafted with `{REF}:` prefix, `git add` + `git commit` run, session **remains open**. No HANDOFF/NEXT updates.

**Commit and push (no close):**

```
session-control commit push
```

Expect: same as commit, then `git push`. Session stays open.

---

## Mode comparison

| | start | status | close | close commit | close commit push | **commit** | **commit push** |
|---|-------|--------|-------|--------------|-------------------|-----------|----------------|
| Read HANDOFF/NEXT | yes | yes | yes | yes | yes | **no** | **no** |
| Update HANDOFF | Open | no | Closed | Closed | Closed | **no** | **no** |
| Update NEXT | no | no | yes | yes | yes | **no** | **no** |
| `git commit` | no | no | no | yes | yes | **yes** | **yes** |
| `git push` | no | no | no | no | yes | **no** | **yes** |
| Commit message in output | no | no | **always** | **always** | **always** | **always** | **always** |
| Completion checklist | yes | no | yes | yes | yes | **yes** | **yes** |
| Task ref auto-detected | - | - | - | yes | yes | **yes** | **yes** |
| Query GitHub task registry (optional) | yes | no | no | yes | yes | **yes** | **yes** |

---

## HANDOFF - Session status templates

### Open (after start)

```markdown
## Session status

**Open:** 2026-05-18 - goal: bootstrap platform health route

**Updated:** 2026-05-18

Treat prior closed sessions as historical only; see "What this cycle produced" below.
```

### Closed (after close)

```markdown
## Session status

**Closed:** 2026-05-18 - platform skeleton landed; tests not yet run

**Updated:** 2026-05-18

Treat the next chat as a **new session**: do not assume unwritten goals from prior threads unless they appear in this file or linked artifacts.
```

---

## Git commands reference

| Purpose | Command |
|---------|---------|
| Short status | `git status -sb` |
| Close audit | `git status` + `git diff --stat` + `git diff --cached --stat` |
| After commit | `git log -1 --oneline` |
| Split advice | `git diff --name-only` grouped by top-level dir |

| When | Allowed |
|------|---------|
| `close` | audit only |
| `close commit` | `git status --porcelain` → detect repo mode → stage safe in-scope paths (framework source: whole repo; consumer: `.work/` + root `PROCESS_ROUTER.md`/`DOCS_TECH_STACK.md`/`CHANGELOG.md` if present; incl. new untracked files/dirs) → `git commit` → `git status -sb` |
| `close commit scoped` | `git add` HANDOFF + NEXT (+ session-listed paths only) |
| `close commit push` | above + `git push` |
| `commit` | same as `close commit` but **no** HANDOFF/NEXT update |
| `commit push` | same as `close commit push` but **no** HANDOFF/NEXT update |

Never on default `close`: commit or push. **Standalone `commit` / `commit push`** always runs git.

---

## Commit message rules (summary)

- Subject ≤72 chars, imperative (`docs: update HANDOFF for session close`).
- Body: why, not file list; omit if subject suffices.

## Commit message examples

**Docs-only session (no task ref):**

```
docs: add session-control skill and update HANDOFF

Session bookends for context load and close hygiene; no application code.
```

**Planning + infra (no task ref):**

```
docs: close planning session - docker compose approved

HANDOFF and NEXT updated; compose files on disk; application source not started.
```

**Feature work with task ref (auto-detected from branch `feature/PROJ-456-login-form`):**

```
PROJ-456: Add login form with email validation

- Email regex validation on submit
- Error state styling for invalid input
```

**Feature work without task ref (no match in HANDOFF or branch):**

```
feat: add platform health route and settings scaffold

FastAPI /health with DB ping; pydantic Settings from env per CONVENTIONS.
```

---

## Bootstrap (no HANDOFF yet)

**Path:** handoff lives at **`.work/context/HANDOFF.md`** (not `context/HANDOFF.md` at repo root). See `skill.md` § Path resolution.

If `.work/context/HANDOFF.md` is missing:

1. Tell user HANDOFF is required for session-control.
2. Offer: create minimal HANDOFF from README + `git log` **or** run `plan-foundation` greenfield first.
3. Minimal HANDOFF sections: Session status, Repository state, Recommended pick-up, Fresh start checklist.

Do not invent project history.

---

## Integration with other skills

| Skill | When |
|-------|------|
| `plan-foundation` **status** | Optional on start (know planning stage) or close (gate delta) |
| `plan-foundation` **continue** | User goal is planning-only at session start |
| User commit rule | Overrides any urge to commit on close |

---

## Edge cases

| Situation | Behavior |
|-----------|----------|
| Merge conflict markers in tree | close checklist **fail**; list files |
| Only `.ai/` / app dirs changed | Consumer repo: outside `.work/` + general-files scope — session commit stages nothing; list as follow-up for a separate commit. Framework source repo: in scope (whole-repo mode) |
| `credentials/` in `git status` | **fail** secrets check; do not summarize content |
| User closes mid-task | HANDOFF notes "in-flight: …" under Repository state |
| Multiple logical commits | close report suggests 2+ message blocks |
| HANDOFF already Open, new `start -` goal | Set Open line to new goal + today's date; note prior goal in start report |
| HANDOFF says Open but user runs start again (same goal) | Refresh date only; do not duplicate artifact table |
| Git submodules dirty | `git submodule status`; flag dirty subs; audit each if relevant |
| Secrets scan fail | **Halt** close - no HANDOFF/NEXT/commit until resolved |

---

## Wrong prompts

| Prompt | Problem | Use instead |
|--------|---------|-------------|
| `close` expecting auto-commit | Default is draft only | `close commit` |
| `close commit` but tree still dirty | Agent staged HANDOFF-only or skipped shell git | Re-run close; agent must follow C4b default scope |
| `close commit` for bookend files only | Default commits the repo-mode scope (framework source: whole repo; consumer: all safe changes under `.work/` + general root files) | `close commit scoped` |
| `close push` without `commit` | Skill maps to commit+push | `close commit push` |
| `commit` expecting HANDOFF update | Standalone commit skips HANDOFF/NEXT | Use `close commit` instead |
| `commit push` expecting session close | Standalone commit keeps session open | Use `close commit push` instead |
| `start` without reading files | Skill requires evidence | Full start protocol |
| `delete HANDOFF and recreate` | Loses history | Append + update sections |
| `close` with failing tests unmentioned | Violates honesty | Report failures in C2 |
| Omitting commit message from report | Violates skill | Always show ### Commit message |

---

## Optional slash commands (team convention)

| Command | Maps to |
|---------|---------|
| `/sm start` | start |
| `/sm close` | close |
| `/sm close commit` | close commit |
| `/sm close commit push` | close commit push |
| `/sm commit` | commit (no close) |
| `/sm commit push` | commit + push (no close) |

Document in project README if adopted.
---

## Commit protocol (detailed)

<a id="commit-protocol-detailed"></a>

### M1 - Working tree audit (same as C1)

Same as [C1](#c1---working-tree-audit-mandatory).

### M2 - Verification gate (same as C2)

Same as [C2](#c2---verification-gate-this-session).

### M3 - Follow-ups

Same as [C3](#c3---follow-ups-required).

### M4 - Commit message with task ref (always)

**Always** produce the commit message block — even when tree is clean (`none - working tree clean`).

Format per `.cursorrules` (plain text, no surrounding quotes).

**Task ref extraction (auto-detect):**
Look for an active task reference in this priority order:

1. **HANDOFF session goal** — if `{HANDOFF}` `## Session status` contains a ref matching `[A-Z]+-[0-9]+` (e.g. `PROJ-456`), use it.
2. **`.work/active-ref`** — if the file exists (written by session start), read its first line and extract the ref:
   ```bash
   head -1 .work/active-ref 2>/dev/null | grep -oE '[A-Z][A-Z0-9_]*-(T-)?[0-9]+' || true
   ```
   Fastest priority — no network call. Written during `@session-control start` from registry + diff analysis.
 3. **Task registry** — read `.github/task-registry.json` (local file, always available):
    ```bash
    if [ -f ".github/task-registry.json" ]; then
      python3 -c "
import json, sys
with open('.github/task-registry.json') as f:
    data = json.load(f)
for e in data.get('tasks', []) + data.get('tickets', []):
    print(f'{e[\"ref\"]}|{e[\"title\"]}|{e.get(\"status\",\"?\")}')
" 2>/dev/null
    fi
    ```
    Parse entries, match against HANDOFF goal, changed files, or descriptions. If match found, use that ref. If no match, continue.
4. **Branch name** — if current branch matches `(feature|fix|chore|docs)/[A-Z]+-[0-9]+` or `[A-Z]+-[0-9]+/`, extract the ref.
5. **Last commit subject** — if `git log -1 --oneline` starts with `[A-Z]+-[0-9]+`, reuse it.
6. **FAIL** — no ref found at any priority. **Ask the user for the ref manually.** Do NOT proceed without one. If the user cannot provide one, use a placeholder like `no-ref` but log a warning.

**Subject format:**
- Ref found: `{REF}: {subject}` (e.g. `PROJ-456: Add login form with email validation`)
- No ref: **must not happen** — see priority 6 above.

Keep subject ≤72 chars (including ref prefix), imperative mood.

**Body:** optional; wrap ~72 chars; **why**, not file list. Omit if subject is self-contained.

Valid types (when no ref): `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`.

Label in report: **Commit message (draft)** vs **Commit message (used)**.

### M5 - Git actions (modifiers only)

Same as [C4b](#c4b--git-actions-modifiers-only) — default scope, commit via HEREDOC, post-commit verification, push if modifier includes `push`.

**Hard rule - agents MUST execute git:** Typing `@session-control commit` does not commit by itself. The agent **MUST** run shell commands. Checklist item 9 is **fail** if the tree still has unstaged safe changes and no commit SHA was produced.

**Hard rule - no Co-authored-by:** Never add `Co-authored-by:` trailers or `git commit --trailer "Co-authored-by:..."`. Hooks strip/reject them; if a commit still contains a trailer, amend with a clean message before push.

**Clean tree + `commit` modifier:** skip commit; report `Commit message (used): none - working tree clean`.

### M6 - Commit report (mandatory output)

```markdown
## Commit completed - <Project Name>

**Date:** <ISO date> · **Branch:** <branch>

### Checklist
| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Git audit | pass/fail | clean / N files changed |
| 2 | Secrets safe | pass/fail | |
| 3 | Verification honest | pass/fail | |
| 4 | Follow-ups listed | pass | |
| 5 | Commit message shown | pass | always |
| 6 | Task ref extracted | pass/skip | ref or no ref found |
| 7 | Git commit | pass/fail/skip | modifier `commit`; SHA + `git status` evidence |
| 8 | Repo-mode scope staged | pass/fail/skip | leftover safe in-scope paths listed |
| 9 | Git push (if requested) | pass/fail/skip | modifier `push` |

### Commit message
**Status:** draft | used  
**Message:**

    PROJ-456: subject line here

    Optional body.

**Git:** committed \<sha\> | push \<remote/branch\> result

**Session:** still open — no HANDOFF or NEXT changes.
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [SKILL_DEPENDENCIES.md](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## Close protocol (detailed)

<a id="close-protocol-detailed"></a>

**Execution order:** C1 → C2 → C3 → C4 (draft message) → C5 (HANDOFF) → C6 (NEXT) → C4b (git, if `commit`/`push`) → C7 (optional) → C8 (report).

If C1 secrets **fail**, **stop** - do not run C5, C6, or C4b; report failure in C8.

### C1 - Working tree audit (mandatory)

```bash
git status
git diff --stat
git diff --cached --stat
```

Classify:

| Finding | Action |
|---------|--------|
| Uncommitted changes | Summarize by area; draft commit message(s) |
| Untracked files | Flag if unexpected; remind `.gitignore` / secrets |
| Staged only | Note ready to commit |
| Clean tree | State explicitly |

**Secrets scan (mandatory):** Before summarizing diffs, confirm `git status` does not list paths matching: `credentials/`, `.env`, `.env.*` (except `.env.example`), `*.pem`, `*.p12`, `*.key`, `*.pfx`, `*.p8`, `*id_rsa*`, `*.token`, `*.secret`. If any match → checklist **fail**, **halt close** (no HANDOFF/NEXT/git); tell user to unstage/remove and never commit content.

### C2 - Verification gate (this session)

Per `.cursorrules` Completion Gate - answer honestly:

| Question | Answer |
|----------|--------|
| Code changed this session? | yes / no |
| Tests/lint/build run? | yes / no / n/a |
| All passed? | yes / no / partial |
| What remains unverified? | list |

Do not claim "all good" if tests failed.

**Probe ledger pre-check (only if a `PROBE_LEDGER.md` exists):** run `bash .ai/scripts/readiness-verify.sh`. On **fail** (uncited `confirmed/high`, inflated Coverage %, or `coverage ≥ target` with a gate-blocking dimension still `unknown`), record it under [C3](#c3--follow-ups-required) and recommend `@plan-foundation probe` / `@plan-master probe` - do **not** claim planning is ready.

**Traceability pre-check (only if a master plan exists):** run `bash .ai/scripts/traceability-verify.sh`. On **fail** (an FR maps to no task `M{N}-T{N}`), record under [C3](#c3--follow-ups-required) and recommend `@plan-master revise` / `@plan-repair master` - do **not** claim the plan is implementation-complete.

### C3 - Follow-ups required

Detect and list:

- [ ] Uncommitted work needing commit (or intentional WIP)
- [ ] HANDOFF / NEXT out of date vs actual repo
- [ ] Open ADRs blocking the work touched
- [ ] Owner actions (legal review, vendor approvals, schema packs, etc.)
- [ ] Docker/infra left running (optional note)
- [ ] Temp files under `tmp/` that should be deleted
- [ ] SPECs promised but not written
- [ ] Archived prompts at risk of edit - **warn**

### C4 - Commit message with task ref (always)

**Always** produce the commit message block in the close report - even when the tree is clean (`none - working tree clean`).

Format per `.cursorrules` (plain text, no surrounding quotes).

**Task ref extraction (auto-detect):**
Look for an active task reference in this priority order:

1. **HANDOFF session goal** — if `{HANDOFF}` `## Session status` contains a ref matching `[A-Z]+-[0-9]+` (e.g. `PROJ-456`), use it.
2. **`.work/active-ref`** — if the file exists (written by session start), read its first line and extract the ref:
   ```bash
   head -1 .work/active-ref 2>/dev/null | grep -oE '[A-Z][A-Z0-9_]*-(T-)?[0-9]+' || true
   ```
   Fastest priority — no network call. Written during `@session-control start`.
 3. **Task registry** — read `.github/task-registry.json` (local file, always available):
    ```bash
    if [ -f ".github/task-registry.json" ]; then
      python3 -c "
import json, sys
with open('.github/task-registry.json') as f:
    data = json.load(f)
for e in data.get('tasks', []) + data.get('tickets', []):
    print(f'{e[\"ref\"]}|{e[\"title\"]}|{e.get(\"status\",\"?\")}')
" 2>/dev/null
    fi
    ```
    Parse entries, match against HANDOFF goal, changed files, or descriptions. If match found, use that ref. If no match, continue.
4. **Branch name** — if current branch matches `(feature|fix|chore|docs)/[A-Z]+-[0-9]+` or `[A-Z]+-[0-9]+/`, extract the ref.
5. **Last commit subject** — if `git log -1 --oneline` starts with `[A-Z]+-[0-9]+`, reuse it.
6. **FAIL** — no ref found at any priority. **Ask the user for the ref manually.** Do NOT proceed without one.

**Subject format:**
- Ref found: `{REF}: {subject}` (e.g. `PROJ-456: Add login form with email validation`)
- No ref: **must not happen** — see priority 6 above.

Keep subject ≤72 chars (including ref prefix), imperative mood (`add`, `fix`, not `added`).

- **Body:** optional; wrap ~72 chars; **why**, not file list. Omit if subject is self-contained.

- One message if changes are cohesive; suggest **split** with multiple message blocks if not.
- Label in report: **Commit message (draft)** vs **Commit message (used)**.

### C4b - Git actions (modifiers only)

| Modifier | Action |
|----------|--------|
| *(none)* | Message only. User runs `git commit` themselves. |
| `commit` | Only if C1 secrets **pass**. After C5/C6 (close) **or** after M4 (standalone commit): stage per **default scope** → `git commit` (HEREDOC) → verify tree → record SHA. |
| `commit scoped` | After C5/C6: stage only `{HANDOFF}`, `{ITERATION_CARRIER}`, and paths explicitly tied to this session in the close report. |
| `commit push` | After successful commit: `git push` (current branch). Warn before force-push. |

**Hard rule - agents MUST execute git:** Typing `@session-control close commit` or `@session-control commit` does not commit by itself. The agent **MUST** run shell commands below. Checklist item 6 (close) / item 7 (commit) is **fail** if the tree still has unstaged safe changes and no commit SHA was produced.

**Default commit scope** (when modifier is `commit` or `commit push`, not `scoped`):

0. **Detect repo mode:** framework source ⇔ repo root contains `agent.os.framework.md`; else consumer.
1. Run `git status --porcelain` (from C1).
2. Build the stage list:
   - **Framework source:** every path in the repo with status `M`, `A`, `D`, `R`, `C`, or `??` (untracked — includes **new untracked files/dirs**).
   - **Consumer:** every path **under `.work/`** with those statuses, **plus** root-level `PROCESS_ROUTER.md`, `DOCS_TECH_STACK.md`, `CHANGELOG.md` **if present**.
   - In **both** modes **except** paths matching:
     - Secrets scan patterns (C1) - never add
     - `tmp/`, `.obfuscation/output/` - never add unless user explicitly named them for commit
     - Protected files per `{AGENT_RULES_FILE}` §Protected Files - **do not add**; list in close report as follow-up
3. Stage (typical):
   ```bash
   # framework source
   git add -A
   # consumer
   git add .work/ PROCESS_ROUTER.md DOCS_TECH_STACK.md CHANGELOG.md 2>/dev/null || git add .work/
   ```
   Or stage explicit paths from step 2 if the diff is small. `git add -A` / `git add .work/` naturally pick up new untracked files/dirs in scope.
4. **Do not** stage anything outside the repo-mode scope — in a consumer, `.ai/` and app dirs stay out of session commits; list out-of-scope paths in the close report as follow-ups.
5. **Do not** default to HANDOFF + NEXT only - that is **`commit scoped`**, not default `commit`.
6. If the only remaining dirty paths are excluded (protected / secrets) or out of scope, commit what was staged and report exclusions.

**Commit command shape:**

```bash
git add <paths-from-scope>
git commit -m "$(cat <<'EOF'
<exact message from C4>
EOF
)"
git status -sb
git log -1 --oneline
```

**Post-commit verification (mandatory):**

| Check | pass when |
|-------|-----------|
| Commit created | `git log -1` shows new SHA |
| Staging complete | No remaining `M`/`D`/`??` in safe in-scope paths from step 2 (framework source: whole repo; consumer: `.work/` + general root files), **or** report lists each leftover path and why (protected, secrets, outside scope, intentional WIP) |

**On commit failure:** report hook output; do not claim close complete for git step; HANDOFF/NEXT updates still stand if already written.

**Clean tree + `commit` modifier:** skip commit; report `Commit message (used): none - working tree clean`.

**Never:** `git commit --no-verify`, `git push --force` unless user explicitly requests in the same message.

### C5 - Update HANDOFF (mandatory on close)

Rewrite top sections (keep history table append-only style):

1. **Session status:** `Closed: <date>` - one-line summary of session outcome.
2. **Updated:** today.
3. **Repository state:** current truth (planning vs code, blockers).
4. **Recommended pick-up file:** point to `NEXT.md`.
5. **What this cycle produced:** append rows for new/updated artifacts (no duplicates).
6. **Explicit unknowns:** refresh from session.
7. **Open owner actions:** refresh.
8. **Foundation gate snapshot** (if project uses doc 04 §14): update table.
9. Remove stale "Open" session line; closed sessions must not say "in progress".

**Cleanup:** Remove `.work/active-ref` if it exists:
```bash
rm -f .work/active-ref
```

Do not delete historical rows in artifact tables; append new entries.

### C6 - Update NEXT.md (mandatory on close)

- Move completed items to **Done** with date.
- Set **one** clear **Recommended next**.
- Refresh **Blocked on owner**.
- Update foundation gate / pre-merge checklist if applicable.

### C7 - Optional: plan-foundation status

If the repo uses plan-foundation conventions, run **status** (read-only) and attach ≤5 lines - foundation-complete + plan-master-ready (not implementation-ready; that is plan-master).

### C8 - Close report (mandatory output)

```markdown
## Session closed - <Project Name>

**Date:** <ISO date> · **Branch:** <branch>

### Completion checklist
| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Git audit | pass/fail | clean / N files changed |
| 2 | Secrets safe | pass/fail | |
| 3 | Verification honest | pass/fail | |
| 4 | Follow-ups listed | pass | |
| 5 | Commit message shown | pass | always |
| 6 | Git commit (if requested) | pass/fail/skip | modifier `commit`; SHA + `git status` evidence |
| 6b | Repo-mode scope staged (default `commit`) | pass/fail/skip | not `scoped`; leftover safe in-scope paths listed |
| 7 | Git push (if requested) | pass/fail/skip | modifier `push` |
| 8 | HANDOFF updated | pass/fail | |
| 9 | NEXT updated | pass/fail | |
| 10 | Foundation status (optional) | pass/skip | |

### Commit message
**Status:** draft | used  
**Task ref:** <ref or none>  
**Message:** (plain text below - always present)

    PROJ-456: subject line here

    Optional body - why, not what.

**Git:** no commit (default) | committed \<sha\> | push \<remote/branch\> result

### Follow-ups before next session
<ordered list>

### Next session should
<one line from NEXT.md>
```

Any operator-required approval/question in **Follow-ups** must ALSO appear in the closing handoff block (enumerated, with `path:line`), not only in that section. End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [SKILL_DEPENDENCIES.md](../SKILL_DEPENDENCIES.md#operator-handoff-contract).
---

## Start protocol (detailed)

<a id="start-protocol-detailed"></a>

### S1 - Baseline reads (mandatory)

Read these files **in full** (or confirm missing). Record `pass` only after reading.

| # | File (repo-root path) | Pass criteria |
|---|------|----------------|
| 1 | `.cursorrules` | Can state: identity, 7 core principles, protected files, no-commit rule |
| 2 | `.work/context/HANDOFF.md` | Know: session-critical sections (§Session status through §Open owner actions). The artifact table (§What this cycle produced) and tail sections (§Hygiene, §Doc 04 gate, §Tracked inventory) are reference - skim for relevance, not mandatory for start. |
| 3 | `.work/plans/NEXT.md` | Know: single recommended next action + owner blockers |
| 4 | `.work/plans/UNKNOWNS.md` | Know: every open unknown, its `Blocks` target (task / ADR / milestone), and its `Owner`. Cross-check against HANDOFF §Explicit unknowns and §Open owner actions - stale entries must be noted in the start report. |
| 5 | `.work/plans/foundation/*-01-*-initial-scope.md` **if present** | Know one-sentence product intent **or** record *no doc 01 yet* and rely on README / HANDOFF. **Do not** read `.work/prompts/initial.md` unless the user explicitly names it. |

### S1b - Unblock check (when `.work/plans/NEXT.md` has an active iteration)

If `.work/plans/NEXT.md` contains a `## Current iteration` block with task rows:

1. Scan for tasks with status `blocked`.
2. For each `blocked` task, find the blocker entry in `### Owner blockers` and/or `.work/plans/UNKNOWNS.md` (entries with `blocks: T{N}`).
3. Check if the condition has changed: ADR decided, owner action marked done in HANDOFF §Open owner actions, or dependency completed.
4. If resolved → flip task to `pending`; annotate `unblocked YYYY-MM-DD - <reason>`. If the UNKNOWNS row is also resolved, update its `Status` to `Resolved` with date.
5. If unchanged → leave as `blocked`; surface in the start report `### Open blockers (owner)`.
6. If no iteration block exists → skip.

### S2 - Conditional reads (task-based)

If HANDOFF §"Fresh start" lists extras, or the user named a domain, read those paths before claiming start complete.

| Task touches | Read |
|--------------|------|
| Code / new feature | `.work/standards/*CONVENTIONS*`, `.work/standards/*FEATURE_STANDARD*` |
| Stack / infra | `REPLACE:TECH_STACK_DOC` (from `.cursorrules`), `.work/standards/*DIRECTORY_MAP*` |
| External integration | domain SPEC, `{PLANS_ROOT}/foundation/*-02-*.md`, `.work/docs/integration/MANIFEST.txt` on demand |
| Foundation planning | `plan-foundation` skill → **status** mode (read-only) |
| Security / new columns | threat-model, data-classification |

### S3 - Environment snapshot (evidence)

Run (or explain why skipped):

```bash
git status -sb
git log -1 --oneline
```

Optional - running services (use first that works):

```bash
docker compose ps 2>/dev/null || podman-compose ps 2>/dev/null || true
```

Record: branch, clean/dirty, last commit, services up/down if checked.

### S3c - MCP availability (informational, non-blocking)

Check whether MCP server files or project-query-setup integration is present:

```bash
test -d .opencode/mcp/ && echo "MCP_DIR: .opencode/mcp/" || true
test -d .opencode/mcp/project-mcp/ && echo "MCP_PROJECT: .opencode/mcp/project-mcp/" || true
test -f .opencode/mcp/project-mcp/mcp_server.py && echo "MCP_READY=yes" && echo "MCP_CMD=python3 .opencode/mcp/project-mcp/mcp_server.py" || true
```

If MCP server files are detected, check `.work/context/MCP_REGISTRY.md` for prior approvals.  
If a registration exists for `tools-project` on the same MCP server path → no note needed (already approved).  
If MCP server files are detected but no registration exists in the config, add an informational note to the start report:

> ⓘ **MCP server detected** but no coding-agent MCP config found for `tools-project`.  
> If not yet registered, ask your coding agent to register it — provide:
> - Server name: `tools-project`
> - Command: `python3 .opencode/mcp/project-mcp/mcp_server.py`
> - Key file: `~/.tools-project-key` (chmod 600)

This check is **read-only and non-blocking** — it does not gate the session start. If nothing is detected, skip silently.

### S4 - Session goal (interaction)

Capture goal from (in order): text after `start -`, else HANDOFF **Recommended pick-up** / repository state, else ask **once**:

**Q:** What is the primary goal for this session? (one line)

Do **not** ask if goal is already clear from invocation or HANDOFF. Store in start report only; do not rewrite HANDOFF unless user asks.

### S4b - Coding goal readiness (when goal implies implementation)

If the session goal mentions coding, M1, implementation, or a feature task:

1. Run `@plan-master status` (read-only) or read HANDOFF for **Implementation-ready** and milestone waivers.
2. If **implementation-ready: no** and no HANDOFF waiver for the named milestone → note in start report under **### Readiness (do not implement yet)** with redirect: `@plan-master status` → approve plan, or add HANDOFF waiver, or `@code-implementation plan - M{N}` only after prerequisites pass.
3. Do **not** invoke `@code-implementation start` from session-control - route the user to that skill after gates pass.

### S4c - Task registry lookup (mandatory, no-network)

Read `.github/task-registry.json` from the working tree. This is a local
file in the repo — no API call, no network, no running stack.

```bash
REGISTRY=".github/task-registry.json"
if [ ! -f "$REGISTRY" ]; then
  echo "WARNING: no $REGISTRY — task/ticket refs unavailable for this session"
else
  python3 -c "
import json
with open('$REGISTRY') as f:
    data = json.load(f)
for kind in ('tasks', 'tickets'):
    refs = data.get(kind, [])
    for r in refs:
        print(f'{r[\"ref\"]}|{r[\"title\"]}|{r.get(\"status\",\"?\")}')
"
fi
```

**Match entries to choose the active ref:**

1. Read every `ref`, `title`, `description`, `status` from the output.
2. Run `git diff HEAD --stat` to see which files changed.
3. Compare changed file paths against entry `description` texts — pick
   the best match by title/description relevance.
   - If a single entry matches → use its `ref`.
   - If multiple match → prefer `in_progress` > `todo` > `open` status.
   - If none match → **ask the user for the ref manually** — do NOT
     proceed without one.
4. The only valid reason for zero matches is genuinely new work with no
   ticket — the file is always readable.

**Write the chosen ref to `.work/active-ref`:**

```bash
echo "REF_HERE" > .work/active-ref
```

This file is read by the `prepare-commit-msg` hook (priority #2 after
branch name) so every subsequent commit on this session automatically
gets the ref prefix. The hook also supports the conventional branch-name
extraction as priority #1, but `.work/active-ref` ensures that even
commits on branches without a ref pattern are linked.

If the registry was unreachable or empty and the user provided a ref
manually, write that ref to `.work/active-ref` too — the file is the
single source of truth for the session.

### S5 - Mark session open (HANDOFF)

Update **only** the `## Session status` block at the top of `{HANDOFF}`:

- **Open:** `<YYYY-MM-DD>` - goal: \<user goal or "not specified"\>
- **Updated:** today's date
- Preserve prior "Closed" history in `## What this cycle produced` on **close**, not on start.

If user invoked **status** mode, skip S5 and S6 - use [Status protocol](#status-protocol).

### S6 - Start report (mandatory output)

```markdown
## Session started - <Project Name>

**Date:** <ISO date> · **Branch:** <branch> · **Working tree:** clean | dirty

### Completion checklist
| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | .cursorrules read | pass/fail | |
| 2 | HANDOFF read | pass/fail | |
| 3 | NEXT read | pass/fail | |
| 4 | UNKNOWNS read | pass/fail | |
| 5 | P0 initial scope (foundation doc 01) | pass/skip | `{PLANS_ROOT}/foundation/*-01-*.md` or skip |
| 6 | Conditional reads | pass/skip | <paths> |
| 7 | Git snapshot | pass/skip | <one-liner> |
| 8 | Session goal captured | pass | <goal> |
| 9 | HANDOFF marked Open | pass/skip | |

### You are cleared to work when
All mandatory checks (1–4, 6–8) are **pass**, and row **5** is **pass** (doc 01 read) or **skip** (no doc 01 yet - note in report). If any mandatory **fail**, fix before implementation.

### Pick up here
<quote recommended next from NEXT.md>

### Open blockers (owner)
<from HANDOFF / NEXT>

### Principles reminder (3 bullets max)
<from .cursorrules - not a full paste>

### MCP availability
<if MCP detected but not registered: include the ⓘ note from S3c. If registered or absent: omit this section.>
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [SKILL_DEPENDENCIES.md](../SKILL_DEPENDENCIES.md#operator-handoff-contract).
---

## Context protocol (detailed)

<a id="context-protocol-detailed"></a>

### X1 - Mandatory context reads (read in full)

Same set as [S1](#s1--baseline-reads-mandatory):

| # | File (repo-root path) | Pass criteria |
|---|----------------------|----------------|
| 1 | `.cursorrules` | identity, 7 core principles, protected files, no-commit rule |
| 2 | `.work/context/HANDOFF.md` | §Session status → §Open owner actions |
| 3 | `.work/plans/NEXT.md` | Recommended next + owner blockers |
| 4 | `.work/plans/UNKNOWNS.md` | every open unknown + owner + Blocks |
| 5 | `.work/plans/foundation/*-01-*-initial-scope.md` **if present** | one-sentence product intent (or skip) |

Conditional reads per [S2](#s2--conditional-reads-task-based) only when the operator named a domain.

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

## Critical interactions

| When | Ask / do |
|------|----------|
| **Start** | Prior HANDOFF says `Closed` → treat as new session; do not assume prior chat memory |
| **Start** | Missing HANDOFF → offer to run `plan-foundation` greenfield or create minimal HANDOFF |
| **Start** | Dirty tree at start → note in report; ask if continuing WIP or stashing |
| **Start** | HANDOFF already **Open**, new `start -` goal differs | Update Open line with new goal + date |
| **Close** | Large uncommitted diff → suggest commit split |
| **Close** | User says "close without updating HANDOFF" → only allowed if they confirm; mark checklist item `skip` with reason |
| **Close** | Protected files changed → flag for explicit owner review |
| **Close** | `close commit` / `close commit push` → run C4b in shell after HANDOFF/NEXT; stage per **repo-mode scope** (framework source: whole repo; consumer: `.work/` + general root files) |
| **Close** | User expected commit but tree still dirty → **fail** item 6/6b |
| **Commit** | `@session-control commit` → Run Commit protocol; **do not** update HANDOFF or NEXT |
| **Commit** | No task ref found → Ask user once (M4/C4 priority 6) |

---

## Anti-patterns

- Claiming "context loaded" without reading HANDOFF and NEXT
- Closing session without updating HANDOFF and NEXT
- Committing on plain `close` (without `commit` modifier)
- **`close commit` with only HANDOFF/NEXT staged** while other safe `.work/` paths remain dirty
- **Reporting close commit done without running `git commit`** or without a new SHA
- Omitting the commit message block from the close report
- Putting secrets or PII in HANDOFF
- Marking checklist `pass` without evidence
- Continuing close after secrets scan **fail**
- Running HANDOFF/NEXT updates on standalone `commit` or `commit push`
- Adding `Co-authored-by:` trailers or using `git commit --trailer "Co-authored-by:..."`
- Burying operator actions/questions in prose instead of the closing handoff block (Form A single line / Form B labeled sections)

---

## Project layout (convention)

**`{WORK_ROOT}` = `.work/`** at repo root (sibling of `.ai/` in consumer repos). Not the git root itself.

```
.work/                          ← {WORK_ROOT}
  context/HANDOFF.md            ← session-control ({HANDOFF})
  plans/NEXT.md                 ← session-control + code-implementation ({ITERATION_CARRIER})
  features/                     ← feature-spec ({FEATURE_SPEC_ROOT})
  prompts/                      ← plan-foundation P0 ({PROMPTS_ROOT})
  decisions/                    ← ADRs ({DECISIONS_ROOT})
.ai/skills/                     ← portable skills only
```

Projects without `.work/context/HANDOFF.md`: run `@project-bootstrap init` or `@deploy-files` in-place.
