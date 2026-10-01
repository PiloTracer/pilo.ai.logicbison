---
name: plan-sync
description: >-
  Optional integration: parse a plan markdown file into a validated manifest and import it
  into tools-project via the REST API (POST /v1/projects/{id}/plan-import). Dry-run gate
  and operator confirmation required.
---

# plan-sync

**Purpose:** Parse a plan markdown file (typically the live plan `.work/plans/full/*-full-plan.md`; any plan path may be passed) into a JSON manifest v1 and import it into tools-project via the transactional `plan-import` endpoint. Dry-run preview and explicit operator confirmation are mandatory.

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
  "source_path": ".work/plans/full/20260925-full-plan.md",
  "plan_version": "v1.9",
  "project": {"name": "…", "key": "…", "description": "…"},
  "milestones": [{"plan_ref": "M1", "key": "M1", "name": "…", "summary": "One plain sentence describing the milestone goal.", "description": "…", "sort_order": 1, "status": "pending"}],
  "tasks": [{"plan_ref": "M1-T1", "milestone_ref": "M1", "title": "Enterprise customization cascade (T3, ADR 020)", "description": "## Intent\nImplement the location scope layer cascade (org default → practice → clinic) with safety floors.\n\n## Acceptance\n- A lower scope cannot override an org safety floor\n- A blueprint import carries no PHI and lands disabled\n\n## Technical details\n- plan_ref: M12-T15\n- plan_version: 1.9\n- source: .work/plans/full/20260925-full-plan.md\n- files: customization/**, platform/\n- traces: FR26, NFR19\n- complexity: L", "status": "pending"}],
  "components": []
}
```

**Constants to embed:**
- `manifest_version` must be `1` (server rejects anything else with 400).
- `plan_ref`: milestones `^M\d+$`, tasks `^M\d+-T\d+$`; unique within the manifest; every task's `milestone_ref` must exist in `milestones[]`.
- Limits: `tasks ≤ 500`, `milestones ≤ 100`; `title` 1–120 chars; `name` 1–200 chars.
- Task status vocabulary — accepts **plan** or app vocab; mapping applied server-side: `pending→todo`, `done→done`, `blocked→blocked`, `deferred→cancelled` (app vocab `todo|in_progress|blocked|done|cancelled` passes through).
- Milestone status: `pending | active | blocked | done | cancelled` (default `pending`). At most one `active` per project at commit (server enforces).
- **Milestone `summary`**: one plain sentence (the plan's milestone heading or goal line). Rendered by tools-project under the milestone name. Required for every milestone.
- **Status application:** statuses are applied **at task creation only**. Tasks that already exist in the app keep their local status (importer R13); a differing plan status is reported as an informational `status_divergence` conflict, never auto-overwritten. Plan `done` on an existing `todo` task therefore needs a manual change in the app UI after import.

---

## Parsing rules (plan markdown → manifest)

From the actual plan format (`.work/plans/full/*-full-plan.md`):
- **Milestone** = `### M<n> — <name>` heading sections (metadata: `**Objective:**`, `**Scope — in/out:**`, `**Deliverables:**`, …). Populate `plan_ref: "M<n>"`, `name`, `description` from the section body, `sort_order` = section order. **`summary`** = one plain sentence from the milestone heading or its goal line (e.g., the `**Objective:**` first sentence). Required.
- **Tasks** = the `#### Tasks - M<n>: …` tables: columns `| ID | Description | Files | FR/NFR | Complexity | Acceptance | Status |`. `ID` → `plan_ref` (e.g. `M1-T1`), its section → `milestone_ref`.
- `title` = **short human label**, ≤120 chars, no markdown emphasis markers (`**`, `__`, backticks), no trailing ellipsis. Derive from the `Description` cell: take the leading bold label or first clause before `—`/em-dash. Example: `**Enterprise customization cascade (T3, ADR 020)** — the \`location\` scope layer…` → `Enterprise customization cascade (T3, ADR 020)`.
- `description` = compose exactly three headings in this order, no `---` rule, no inline `**Provenance:**` line:

  ```markdown
  ## Intent
  <one plain-language sentence: what this task delivers, in the plan's own words where possible>

  ## Acceptance
  - <criterion 1>
  - <criterion 2>

  ## Technical details
  - plan_ref: M12-T15
  - plan_version: 1.9
  - source: .work/plans/full/20260925-full-plan.md
  - files: customization/**, platform/
  - traces: FR26, NFR19
  - complexity: L
  ```

  Rules:
  - **A1** Heading names and order are **fixed**: `## Intent`, `## Acceptance`, `## Technical details`.
  - **A2** `## Acceptance` items are **one bullet per criterion** — split the `Acceptance` cell on `;` and sentence boundaries instead of emitting one run-on line. Never drop a criterion.
  - **A3** `## Technical details` is a **bullet list of `- key: value` pairs** with exact keys: `plan_ref`, `plan_version`, `source`, `files`, `traces`, `complexity` (rename `fr_nfr` → `traces`; keep FR/NFR ids verbatim, comma-separated).
  - **A4** Values stay **verbatim and lossless**: `plan_ref`, `source`, `plan_version`, FR/NFR ids, file globs, complexity — no truncation, no re-wording.
  - **A5** `## Intent` is derived, never invented: take the plan row's own words (first clause / goal). If no separable summary, use first clause after the leading bold label.
  - **A6** Omit a block **only** when it has no content (`## Technical details` may be absent for plan rows with no provenance; `## Acceptance` may be absent when the plan records none). Never emit an empty heading.
- **`Complexity` must NEVER become `priority`** (SPEC R22) — complexity is description text only.
- `Status` cell → plan status via the mapping above; unknown status → ask operator, never guess.
- `source_path` = the plan file path as given; `plan_version` = derived from the **latest amendment** when the plan has them (e.g. `Amendment (v1.9 — …)`), else the header (`**Version:**` / `# Full Plan v…`), else prompt. **`latest` = the highest `v` number among the `**Amendment (v…)` lines — never the last such block in file order** (plans append out of order: `v1.2, v1.6, v1.7, v1.8, v1.9, v1.5, v1.4, v1.3`), otherwise every task's `plan_version` is mislabelled. When header ≠ latest amendment, surface the derived value in the preview for operator confirmation before POST (headers often lag amendments).
- **Copy freshness:** if the path points at a copy (e.g. under `.work/feedback/plans-import/`), compare its latest amendment (**highest `v`, not file order**) + task count against the live plan first — a stale copy silently syncs outdated content. Drift → stop and ask the operator to refresh the copy or pass the live plan (this skill never writes `.work/`).

---

## Mandatory safety gates

1. **Always `dry_run=true` first** (SPEC R7 — the preview is what the operator approves). Client-side pre-validate against §Manifest envelope before even the dry run.
2. Preview must show: milestones/tasks `created / updated / obsolete / reactivated` counts + full `conflicts[]` (kind, plan_ref, detail) in a readable table **split into `Action required` (resolve before/after commit) and `Informational` (proceeds unchanged — e.g. `status_divergence`)**, and state plainly: *nothing written yet; obsolete = will be flagged, never deleted; local statuses will be preserved — plan-status-ahead-of-local is informational here and appears again in the post-commit follow-up list*.
3. **Real POST only after explicit operator confirmation in the same session.** No confirmation → stop at preview.
4. Re-runs are safe (idempotent upsert matched by `(project_id, plan_ref)`); a second identical import reports `updated` counts, zero creates.
5. Never write to the plan file or anything under `.work/` (sync is one-way, invariant I1). Never edit app code — a format drift is fixed **in this skill**.

---

## Report (post-commit)

Print the server's `PlanImportResult`: per-entity counts, conflict list, plus a one-line pointer to the project's activity feed (one `kind: system` summary row is the audit trail). When the plan's status differs from the resulting local status for any task, print a **Follow-up in app UI** checklist (`M{N}-T{N}`: plan=<status> / app=<status> → set in the app; MCP is read-only, import preserves local status). Close per the Operator handoff contract (Form B if follow-up decisions exist, else Form A).

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
- `plan_version` from the **latest amendment** — the **highest `v` number**, not the last block in file order (see §Parsing rules) — (e.g. `Amendment (v1.9 …)`), else header (e.g. `# Full Plan v1.7` or `**Version:** v1.7`), else prompt; header ≠ latest amendment → show derived value in preview for confirmation.
- Milestones from `### M<n> — <name>` sections (in order).
- Tasks from `#### Tasks - M<n>: …` tables with columns `ID`, `Description`, `Files`, `FR/NFR`, `Complexity`, `Acceptance`, `Status`.
- Build manifest per §Manifest envelope.

**Validation before dry-run:**
- `manifest_version == 1`
- All `plan_ref` unique, correct regex
- All `milestone_ref` exist in milestones
- `tasks ≤ 500`, `milestones ≤ 100`
- `title` 1–120 chars, `name` 1–200 chars
- Every milestone has non-empty `summary`
- Every task `description` starts with `## Intent` and contains `## Acceptance` (when acceptance exists) and `## Technical details` (when provenance exists) — no `**Provenance:**` and no `---` line
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
| Conflicts — action required | N | (kind, plan_ref, detail) — resolve before/after commit |
| Conflicts — informational | N | (kind, plan_ref, detail) — e.g. `status_divergence`, proceeds unchanged |

Print: **Nothing written yet. Obsolete = flagged, never deleted. Local statuses preserved (plan-ahead statuses → follow-up list).**

**Preview sample (one task):** show the composed `title` (≤120 chars, single clause), and the `description` with `## Intent`, `## Acceptance` bullets, `## Technical details` list — so the operator can verify the new format before confirming.

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

Show modes table, auth setup (`@project-query-setup key`), limits (500 tasks, 100 milestones), manifest version (1), endpoint (`POST /v1/projects/{id}/plan-import`), and that dry-run is mandatory before commit. Note that tasks now use the three-block description format (`## Intent`, `## Acceptance`, `## Technical details`), titles are short labels (≤120 chars, no markdown), and milestones include a one-sentence `summary`.

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
| Plan import SPEC | `.work/features/plan-sync/20260929-SPEC.md` (tools-project repo) |
| MCP server (read-only) | `.opencode/mcp/project-mcp/mcp_server.py` |
| Auth/key setup | `@project-query-setup key` |
| Operator handoff contract | `.ai/skills/SKILL_DEPENDENCIES.md` |