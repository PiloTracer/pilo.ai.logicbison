# plan-sync — Sync Plan Markdown to tools-project

Optional integration: parse a plan markdown file into a validated manifest v1 and import it into tools-project via `POST /v1/projects/{id}/plan-import`. Dry-run preview and explicit operator confirmation are mandatory.

**Prerequisites:** tools-project instance reachable; API key in `~/.tools-project-key` or `TOOLS_PROJECT_API_KEY` env (same resolution as `project-query-setup` + MCP).

---

## Quick Start

```text
# 1. Ensure API key exists (run once)
@project-query-setup key

# 2. Verify connectivity + list reachable projects
@plan-sync status

# 3. Dry-run preview (always run this first — nothing written yet)
@plan-sync dry-run - .work/feedback/plans-import/plans/20260925-full-plan.md

# 4. Confirm & commit (only after reviewing preview)
@plan-sync sync - .work/feedback/plans-import/plans/20260925-full-plan.md

# 5. Re-run is safe (idempotent upsert by project_id + plan_ref)
@plan-sync sync - .work/feedback/plans-import/plans/20260925-full-plan.md
# → reports 0 creates, N updated
```

---

## Modes

| Invocation | Behavior |
|------------|----------|
| `@plan-sync status` | Key + base URL check; lists reachable projects |
| `@plan-sync sync - <plan path>` | Full flow: parse → validate → **dry-run** → preview → confirm → commit → report |
| `@plan-sync dry-run - <plan path>` | Same as sync but stops after preview; never commits |
| `@plan-sync help` | Usage, auth setup pointer, limits |

**Optional:** `--project <uuid|slug|project_key>` on sync/dry-run. If omitted or not UUID: resolves via `GET /v1/agent/projects`, matches `slug`/`project_key`, shows match for confirmation before POST. Ambiguous → asks, never guesses.

---

## Safety Gates (Non-Negotiable)

1. **Always `dry_run=true` first** — the preview is what the operator approves.
2. Preview shows: milestones/tasks `created / updated / obsolete / reactivated` counts + full `conflicts[]` table, and states: *nothing written yet; obsolete = flagged, never deleted; local statuses preserved*.
3. **Real POST only after explicit operator confirmation in the same session.** No confirmation = stop at preview.
4. Re-runs are safe (idempotent upsert by `(project_id, plan_ref)`).
5. **Never** writes to the plan file or anything under `.work/`. Sync is one-way.

---

## Auth & Endpoint Resolution (Mirror MCP Exactly)

1. Key: `TOOLS_PROJECT_API_KEY` → `~/.tools-project-key` (first non-`BASE_URL` line) → `AGENT_API_KEY` (legacy).
2. Base URL: `API_BASE_URL` → `BASE_URL=` in key file → `http://localhost:8300`.
3. Remote `BASE_URL` must be `https://…`.
4. Missing key → prints `@project-query-setup key` guidance. Never invents a key.
5. **Key secrecy:** never prints/logs key; never on command line (`ps`-visible); reads file and sets header in-process.

---

## Manifest v1 (Embedded Constants)

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

**Limits:** `tasks ≤ 500`, `milestones ≤ 100`; `title` 1–200 chars; `name` 1–200 chars.
**Status mapping (plan → app):** `pending→todo`, `done→done`, `blocked→blocked`, `deferred→cancelled`. App vocab (`todo|in_progress|blocked|done|cancelled`) passes through.

---

## Parsing Rules (Plan Markdown → Manifest)

- **Milestones** = `### M<n> — <name>` sections (metadata: `**Objective:**`, `**Scope — in/out:**`, `**Deliverables:**`…). `plan_ref: "M<n>"`, `sort_order` = section order.
- **Tasks** = `#### Tasks - M<n>: …` tables: columns `ID`, `Description`, `Files`, `FR/NFR`, `Complexity`, `Acceptance`, `Status`.
  - `ID` → `plan_ref` (e.g. `M1-T1`), section → `milestone_ref`.
  - `title` = `Description` cell **truncated to ≤200 chars**.
  - `description` = `Acceptance` cell + provenance block (`plan_ref`, source file, plan version, `Files`, `FR/NFR`, `Complexity`).
  - **`Complexity` NEVER becomes `priority`** — complexity is description text only.
- `source_path` = plan file path; `plan_version` = from header or prompted.

---

## Examples

```text
# Full flow (thin-client target project, e.g. tools-project)
@plan-sync status
# → Key file: present (~/.tools-project-key)  Permissions: 600  API: reachable (https://project.cloudsys.win)  Auth: ok  Projects: 2 accessible  MCP tools: 5 registered

@plan-sync dry-run - .work/feedback/plans-import/plans/20260925-full-plan.md --project demo-workspace
# → Dry-run preview table:
#    Milestones created: 12  Tasks created: 153  Conflicts: 0
#    Nothing written yet. Obsolete = flagged, never deleted. Local statuses preserved.
#    **Needs your approval:** Proceed with import to Project Hub (d942e263-efbc-4d96-bc9a-ea33654c3cb4)?
#    **Next step:** @plan-sync sync - .work/feedback/plans-import/plans/20260925-full-plan.md --project d942e263-efbc-4d96-bc9a-ea33654c3cb4 --confirm

@plan-sync sync - .work/feedback/plans-import/plans/20260925-full-plan.md --project d942e263-efbc-4d96-bc9a-ea33654c3cb4 --confirm
# → PlanImportResult: milestones 12 created, tasks 153 created, 0 conflicts
#    Activity feed: https://project.cloudsys.win/projects/d942e263-efbc-4d96-bc9a-ea33654c3cb4/activity

# Re-run (idempotent)
@plan-sync sync - .work/feedback/plans-import/plans/20260925-full-plan.md --project d942e263-efbc-4d96-bc9a-ea33654c3cb4
# → PlanImportResult: milestones 0 created / 12 updated, tasks 0 created / 153 updated, 0 conflicts
```

---

## Anti-Patterns to Refuse

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
| Skill contract | `skills/plan-sync/skill.md` |
| Plan import SPEC | tools-project: `.work/features/plan-sync/20260929-SPEC.md` |
| Auth/key setup | `@project-query-setup key` |
| Operator handoff contract | `skills/SKILL_DEPENDENCIES.md` |