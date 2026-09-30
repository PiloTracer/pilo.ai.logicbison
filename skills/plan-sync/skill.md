---
name: plan-sync
description: >-
  Optional integration: parse a plan markdown file into a validated manifest and import it
  into tools-project via the REST API (POST /v1/projects/{id}/plan-import). Dry-run gate
  and operator confirmation required.
---

# plan-sync

**Purpose:** Parse a plan markdown file (from `.work/feedback/plans-import/plans/*.md`) into a JSON manifest v1 and import it into tools-project via the transactional `plan-import` endpoint. Dry-run preview and explicit operator confirmation are mandatory.

**Deploy to:** Any Agent OS framework (`.ai`, `.ai.ui`, `.ai.biz`, `.ai.soc`, `.ai.cto`, `.ai.flutter`, `.ai.mlt`) — optional integration.

**Prerequisites:** tools-project instance reachable; API key in `~/.tools-project-key` or `TOOLS_PROJECT_API_KEY` env (same resolution as `project-query-setup` + MCP).

---

## Hard rules

1. **Read-only toward plan sources and the repo.** The **only** write is the single `POST …/plan-import` call, gated by operator confirmation.
2. **Never commit without operator confirmation.** Dry-run → preview → explicit `yes` → commit. No confirmation = stop at preview.
3. **Key secrecy:** never print/echo/log the key; never pass it on a command line (`ps`-visible) — read the file and set the header in-process or via stdin; never write key material to `tmp/`, repo files, or shell history; remote `BASE_URL` must be `https://…`.
4. **No MCP changes; no new endpoints; no local database access; no raw SQL.** The MCP remains read-only (project-query-setup hard rule 2).
5. **Auth/RBAC failures are reported, never worked around.** No privilege escalation attempts, no key sharing.
6. **Terse responses; Operator handoff contract (Form A/B) at end of turn.** Per [SKILL_DEPENDENCIES.md](../SKILL_DEPENDENCIES.md#operator-handoff-contract).
7. **Agent parses semantics, not a rigid grammar.** If a section is ambiguous or a table lacks the documented columns → stop and ask (proposal D3 rejected deterministic parsers for exactly this reason).
8. **Never edit the plan file or anything under `.work/`.** Sync is one-way (invariant I1). Format drift is fixed **in this skill**.

---

## Modes

| Invocation | Mode |
|------------|------|
| `@plan-sync status` | Connectivity + key + base URL check; list reachable projects (also the setup verification) |
| `@plan-sync sync - <plan path>` | Full flow: parse → validate → **dry-run** → preview → operator confirmation → commit → report (default) |
| `@plan-sync dry-run - <plan path>` | Same as sync but stops after the preview; never commits |
| `@plan-sync help` | Usage, auth setup pointer (`@project-query-setup key`), limits |

**Optional argument on sync/dry-run:** `--project <uuid|slug|project_key>`. If omitted or not a UUID: resolve via `GET /v1/agent/projects` with the same key, match `slug`/`project_key`, and **show the matched project name + id for operator confirmation before any POST**. If ambiguous → ask, never guess.

---

## Auth & endpoint resolution (mirror the MCP exactly — zero new config)

1. Key: env `TOOLS_PROJECT_API_KEY` → file `~/.tools-project-key` (first line that is not `BASE_URL=…`) → env `AGENT_API_KEY` (legacy). Same order as `mcp_server.py:41-56`.
2. Base URL: env `API_BASE_URL` → `BASE_URL=` line in the key file → `http://localhost:8300`. Same as `mcp_server.py:59-74`.
3. Missing/empty key → stop, print `@project-query-setup key` guidance. Never invent a key.
4. **Security hard rules (copy into skill):** never print/echo/log the key; never pass it on a command line (`ps`-visible) — read the file and set the header in-process or via stdin; never write key material to `tmp/`, repo files, or shell history; remote `BASE_URL` must be `https://…`.
5. HTTP status mapping:
   - `401` → key missing/invalid → `@project-query-setup key`
   - `403` → project role < contributor → ask owner for role
   - `404` → wrong project id
   - `400` → print the field-error list verbatim and fix the manifest (nothing was written)
   - `500` → project unchanged (transaction rolled back) → report and stop

---

## Manifest envelope (v1) — embed this in the skill

```json
{
  "manifest_version": 1,
  "source_path": ".work/feedback/plans-import/plans/20260925-full-plan.md",
  "plan_version": "v1.7",
  "project": {"name": "…", "key": "…", "description": "…"},
  "milestones": [{"plan_ref": "M1", "key": "M1", "name": "…", "description": "…", "sort_order": 1, "status": "pending"}],
  "tasks": [{"plan_ref": "M1-T1", "milestone_ref": "M1", "title": "…", "description": "…", "status": "pending"}],
  "components": []
}
```

**Constants to embed:**
- `manifest_version` must be `1` (server rejects anything else with 400).
- `plan_ref`: milestones `^M\d+$`, tasks `^M\d+-T\d+$`; unique within the manifest; every task's `milestone_ref` must exist in `milestones[]`.
- Limits: `tasks ≤ 500`, `milestones ≤ 100`; `title` 1–200 chars; `name` 1–200 chars.
- Task status vocabulary — accepts **plan** or app vocab; mapping applied server-side: `pending→todo`, `done→done`, `blocked→blocked`, `deferred→cancelled` (app vocab `todo|in_progress|blocked|done|cancelled` passes through).
- Milestone status: `pending | active | blocked | done | cancelled` (default `pending`). At most one `active` per project at commit (server enforces).

---

## Parsing rules (plan markdown → manifest)

From the actual plan format (`.work/feedback/plans-import/plans/20260925-full-plan.md`):
- **Milestone** = `### M<n> — <name>` heading sections (metadata: `**Objective:**`, `**Scope — in/out:**`, `**Deliverables:**`, …). Populate `plan_ref: "M<n>"`, `name`, `description` from the section body, `sort_order` = section order.
- **Tasks** = the `#### Tasks - M<n>: …` tables: columns `| ID | Description | Files | FR/NFR | Complexity | Acceptance | Status |`. `ID` → `plan_ref` (e.g. `M1-T1`), its section → `milestone_ref`.
- `title` = `Description` cell **truncated/edited to ≤200 chars** (plan cells can be ~1400 chars — never send them as title).
- `description` = `## Acceptance` cell content first (the contract), then a provenance block (`plan_ref`, source file, plan version, `Files`, `FR/NFR`, `Complexity`) — SPEC R21.
- **`Complexity` must NEVER become `priority`** (SPEC R22) — complexity is description text only.
- `Status` cell → plan status via the mapping above; unknown status → ask operator, never guess.
- `source_path` = the plan file path as given; `plan_version` = from the plan header if present, else prompt.

---

## Mandatory safety gates

1. **Always `dry_run=true` first** (SPEC R7 — the preview is what the operator approves). Client-side pre-validate against §Manifest envelope before even the dry run.
2. Preview must show: milestones/tasks `created / updated / obsolete / reactivated` counts + full `conflicts[]` (kind, plan_ref, detail) in a readable table, and state plainly: *nothing written yet; obsolete = will be flagged, never deleted; local statuses will be preserved*.
3. **Real POST only after explicit operator confirmation in the same session.** No confirmation → stop at preview.
4. Re-runs are safe (idempotent upsert matched by `(project_id, plan_ref)`); a second identical import reports `updated` counts, zero creates.
5. Never write to the plan file or anything under `.work/` (sync is one-way, invariant I1). Never edit app code — a format drift is fixed **in this skill**.

---

## Report (post-commit)

Print the server's `PlanImportResult`: per-entity counts, conflict list, plus a one-line pointer to the project's activity feed (one `kind: system` summary row is the audit trail). Close per the Operator handoff contract (Form B if follow-up decisions exist, else Form A).

---

## Procedure (sync mode)

### Step 1 — Resolve auth & endpoint

```bash
# Key resolution (mirror mcp_server.py)
if [ -n "$TOOLS_PROJECT_API_KEY" ]; then
  KEY="$TOOLS_PROJECT_API_KEY"
elif [ -f ~/.tools-project-key ]; then
  KEY=$(grep -v '^BASE_URL=' ~/.tools-project-key | head -n1)
elif [ -n "$AGENT_API_KEY" ]; then
  KEY="$AGENT_API_KEY"
else
  echo "No API key found. Run @project-query-setup key first."
  exit 1
fi

# Base URL resolution
if [ -n "$API_BASE_URL" ]; then
  BASE_URL="$API_BASE_URL"
elif [ -f ~/.tools-project-key ] && grep -q '^BASE_URL=' ~/.tools-project-key; then
  BASE_URL=$(grep '^BASE_URL=' ~/.tools-project-key | cut -d= -f2-)
else
  BASE_URL="http://localhost:8300"
fi

# Validate remote BASE_URL is https
if [[ "$BASE_URL" != http://localhost* && "$BASE_URL" != http://127.0.0.1* && "$BASE_URL" != https://* ]]; then
  echo "Remote BASE_URL must be https://"
  exit 1
fi
```

### Step 2 — Resolve project

If `--project` argument provided:
- If UUID format → use directly.
- Else → `GET $BASE_URL/v1/agent/projects` with `X-Api-Key`, find match on `slug` or `project_key`.
- If exactly one match → show `Project: <name> (<id>)` and ask for confirmation.
- If zero or multiple → ask operator to disambiguate.

### Step 3 — Parse plan markdown

Read the plan file at `<plan path>`. Extract:
- `plan_version` from header (e.g. `# Full Plan v1.7` or `**Version:** v1.7`), else prompt.
- Milestones from `### M<n> — <name>` sections (in order).
- Tasks from `#### Tasks - M<n>: …` tables with columns `ID`, `Description`, `Files`, `FR/NFR`, `Complexity`, `Acceptance`, `Status`.
- Build manifest per §Manifest envelope.

**Validation before dry-run:**
- `manifest_version == 1`
- All `plan_ref` unique, correct regex
- All `milestone_ref` exist in milestones
- `tasks ≤ 500`, `milestones ≤ 100`
- `title` 1–200 chars, `name` 1–200 chars
- All statuses mapped to valid vocab (unknown → ask)

### Step 4 — Dry-run preview

```bash
curl -s -X POST "$BASE_URL/v1/projects/$PROJECT_ID/plan-import?dry_run=true" \
  -H "X-Api-Key: $KEY" \
  -H "Content-Type: application/json" \
  -d @manifest.json
```

Parse response. Show table:

| Kind | Count | Details |
|------|-------|---------|
| Milestones created | N | … |
| Milestones updated | N | … |
| Milestones obsolete | N | … |
| Tasks created | N | … |
| Tasks updated | N | … |
| Tasks obsolete | N | … |
| Tasks reactivated | N | … |
| Conflicts | N | (kind, plan_ref, detail) |

Print: **Nothing written yet. Obsolete = flagged, never deleted. Local statuses preserved.**

### Step 5 — Operator confirmation (Form B handoff)

```
**Needs your approval:**
1. Proceed with import to project <name> (<id>)? — see manifest.json (lines 1–50)

**Next step:**
`@plan-sync sync - <plan path> --project <id> --confirm`
```

Wait for explicit `yes`. If not `yes` → stop.

### Step 6 — Commit (real POST)

```bash
curl -s -X POST "$BASE_URL/v1/projects/$PROJECT_ID/plan-import" \
  -H "X-Api-Key: $KEY" \
  -H "Content-Type: application/json" \
  -d @manifest.json
```

### Step 7 — Report result

Print `PlanImportResult` from server. Include activity feed pointer. Close per Operator handoff contract.

---

## Procedure (dry-run mode)

Steps 1–4 only. Stop after preview. Close per Operator handoff contract (Form A or B).

---

## Procedure (status mode)

Run key resolution, test `GET /v1/agent/projects`, list project names/ids. Close per Operator handoff contract.

---

## Procedure (help mode)

Show modes table, auth setup (`@project-query-setup key`), limits (500 tasks, 100 milestones), manifest version (1), endpoint (`POST /v1/projects/{id}/plan-import`), and that dry-run is mandatory before commit.

---

## Anti-patterns to refuse

- Claiming "imported" without a live `PlanImportResult` response
- Skipping dry-run and going straight to commit
- Asking the user to paste their API key into chat
- Storing the key in `/tmp` or any non-`~/.tools-project-key` location
- Logging the key value in any output
- Attempting to work around 401/403/404 errors
- Modifying the plan file or any `.work/` artifact
- Inventing a resolution for an ambiguous project match — ask the operator

---

## Reference

| Doc | Path |
|-----|------|
| Plan import SPEC | `.work/features/plan-import/20260820-SPEC.md` (tools-project repo) |
| MCP server (read-only) | `.opencode/mcp/project-mcp/mcp_server.py` |
| Auth/key setup | `@project-query-setup key` |
| Operator handoff contract | `.ai/skills/SKILL_DEPENDENCIES.md` |