# plan-sync — Sync Plan Markdown to tools-project

Optional integration: parse a plan markdown file (typically the live plan) into a validated manifest v1 and import it into tools-project via `POST /v1/projects/{id}/plan-import`. Dry-run preview and explicit operator confirmation are mandatory.

**Prerequisites:** tools-project instance reachable; API key in `~/.tools-project-key` or `TOOLS_PROJECT_API_KEY` env (same resolution as `project-query-setup` + MCP).

---

## Quick Start

```text
# 1. Ensure API key exists (run once)
@project-query-setup key

# 2. Verify connectivity + list reachable projects
@plan-sync status

# 3. Dry-run preview (always run this first — nothing written yet)
@plan-sync dry-run - <plan path>

# 4. Confirm & commit (only after reviewing preview)
@plan-sync sync - <plan path>

# 5. Re-run is safe (idempotent upsert by project_id + plan_ref)
@plan-sync sync - <plan path>
# → reports 0 creates, N updated
```

**Source:** pass the **live plan** (`.work/plans/full/*-full-plan.md`). If given a copy (e.g. under `.work/feedback/plans-import/`), verify latest amendment (**highest `v`, not the last block in file order**) + task count against the live plan first — a stale copy silently syncs outdated content.

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
2. Preview shows: milestones/tasks `created / updated / obsolete / reactivated` counts + full `conflicts[]` table **split into `Action required` vs `Informational` (e.g. `status_divergence`)**, and states: *nothing written yet; obsolete = flagged, never deleted; local statuses preserved — plan-ahead statuses → follow-up list*.
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
  "source_path": ".work/plans/full/<plan>.md",
  "plan_version": "v1.9",
  "project": {"name": "…", "key": "…", "description": "…"},
  "milestones": [{"plan_ref": "M1", "key": "M1", "name": "…", "summary": "One plain sentence describing the milestone goal.", "description": "…", "sort_order": 1, "status": "pending"}],
  "tasks": [{"plan_ref": "M1-T1", "milestone_ref": "M1", "title": "…", "description": "## Intent\n…\n\n## Acceptance\n- …\n\n## Technical details\n- plan_ref: M1-T1\n- plan_version: 1.9\n- source: …\n- files: …\n- traces: …\n- complexity: …", "status": "pending"}],
  "components": []
}
```

**Limits:** `tasks ≤ 500`, `milestones ≤ 100`; `title` 1–120 chars; `name` 1–200 chars.
**Status mapping (plan → app):** `pending→todo`, `done→done`, `blocked→blocked`, `deferred→cancelled`. App vocab (`todo|in_progress|blocked|done|cancelled`) passes through.
**Status application:** statuses apply **at task creation only** — existing tasks keep their local status (importer R13); differing plan status = informational `status_divergence`. Plan `done` on an existing `todo` task needs a manual app-side change (follow-up list in the report). Milestone `summary` is required for every milestone.

---

## Parsing Rules (Plan Markdown → Manifest)

- **Milestones** = `### M<n> — <name>` sections (metadata: `**Objective:**`, `**Scope — in/out:**`, `**Deliverables:**`…). `plan_ref: "M<n>"`, `sort_order` = section order. `summary` = one plain sentence from the heading or goal line.
- **Tasks** = `#### Tasks - M<n>: …` tables: columns `ID`, `Description`, `Files`, `FR/NFR`, `Complexity`, `Acceptance`, `Status`.
  - `ID` → `plan_ref` (e.g. `M1-T1`), section → `milestone_ref`.
  - `title` = **short human label**, ≤120 chars, no markdown markers, no trailing ellipsis — leading bold label or first clause before `—`.
  - `description` = three fixed headings, in order: `## Intent`, `## Acceptance` (one bullet per criterion), `## Technical details` (`- key: value` pairs: `plan_ref`, `plan_version`, `source`, `files`, `traces`, `complexity`).
  - **`Complexity` NEVER becomes `priority`** — complexity is description text only.
  - `Status` cell → mapping above; unknown status → ask operator, never guess.
- `source_path` = plan file path as given; `plan_version` = **latest amendment** = the **highest `v` number**, never the last such block in file order (plans append out of order) (e.g. `Amendment (v1.9 …)`), else header (`**Version:**` / `# Full Plan v…`), else prompt. Header ≠ latest amendment → derived value shown in preview for confirmation.

---

## Examples

```text
# Full flow (thin-client target project, e.g. tools-project)
@plan-sync status
# → Key file: present (~/.tools-project-key)  Permissions: 600  API: reachable (https://project.cloudsys.win)  Auth: ok  Projects: 2 accessible  MCP tools: 5 registered

@plan-sync dry-run - .work/plans/full/20260925-full-plan.md --project demo-workspace
# → Dry-run preview table:
#    Milestones created: 12  Tasks created: 153  Conflicts: 0
#    Nothing written yet. Obsolete = flagged, never deleted. Local statuses preserved (plan-ahead statuses → follow-up list).
#    **Needs your approval:** Proceed with import to Project Hub (d942e263-efbc-4d96-bc9a-ea33654c3cb4)?
#    **Next step:** @plan-sync sync - .work/plans/full/20260925-full-plan.md --project d942e263-efbc-4d96-bc9a-ea33654c3cb4 --confirm

@plan-sync sync - .work/plans/full/20260925-full-plan.md --project d942e263-efbc-4d96-bc9a-ea33654c3cb4 --confirm
# → PlanImportResult: milestones 12 created, tasks 153 created, 0 conflicts
#    Follow-up in app UI (if any): M{N}-T{N}: plan=done / app=todo → set in the app (import preserves local status)
#    Activity feed: https://project.cloudsys.win/projects/d942e263-efbc-4d96-bc9a-ea33654c3cb4/activity

# Re-run (idempotent)
@plan-sync sync - .work/plans/full/20260925-full-plan.md --project d942e263-efbc-4d96-bc9a-ea33654c3cb4
# → PlanImportResult: milestones 0 created / 12 updated, tasks 0 created / 153 updated, 0 conflicts
```

---

## Anti-Patterns to Refuse

- Claiming "imported" without a live `PlanImportResult` response
- Skipping dry-run and going straight to commit
- Syncing a stale copy when the live plan has newer amendments/tasks (run the copy-freshness check)
- Taking the **last `Amendment (v…)` block in file order** as the plan version (plans append out of order — use the highest `v`)
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
