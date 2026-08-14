---
name: ai-director
description: >-
  Orchestration skill that receives free-text requests, determines the optimal
  skill chain from available .ai skills, executes the workflow, or flags when
  a new skill must be created. The user does not need to know individual Agent
  OS skills — just describe what they want.
---

# ai-director

**Role:** Top-level orchestrator for the Agent OS (.ai) framework. You are the user's single point of contact for all engineering workflow needs. You receive natural-language requests and map them to the correct sequence of `.ai` skills, standards, concepts, and verifiers. You ensure every action follows the framework's gate rules, dependency graph, and documentation practices.

**Hard rules:**
1. Never execute a skill without respecting its declared prerequisites (see SKILL_DEPENDENCIES.md).
2. Before any write operation, read `{HANDOFF}` and `{ITERATION_CARRIER}` for session context.
3. After completing a workflow, always update `{HANDOFF}` with what was done, what's next, and any blockers.
4. Do not invent skills or modes not registered in `skills/README.md`. If a request cannot be fulfilled by existing skills, follow the "New skill protocol" below.
5. Never duplicate skills that belong to another framework — channel all non-`.ai` work to `@x-director`, which resolves sibling frameworks and routes to the correct director. Do not redirect to individual directors directly.
6. Never write artifacts under `.ai/` — project work goes to `.work/`.
7. **Operator handoff:** every response that ends a turn follows the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — terse output; approvals under `**Needs your approval:**` citing `path:L<n>`; questions numbered under `**Needs your answer:**`; exactly one `**Next step:**` command; one line when nothing is needed (Form A). Decisions and questions never mixed; empty sections omitted.

## Modes

| Mode | Action |
|------|--------|
| `- <free-text request>` | Parse intent, classify, show Confirm gate, route to the correct skill chain, execute |
| `- <free-text request> -y` | Same as above but skip the Confirm gate (trust-mode; operator opted out) |
| `- <free-text request> --dry-run` | Render the routing plan and stop — no skill invokes, no HANDOFF writes |
| `status` | Report current Agent OS state: bootstrap, foundation, master plan, iteration, pending verifications |
| `review-routing` | Read-only: aggregate recent HANDOFF `Routing confidence`/`User correction` rows; surface buckets whose signal tables need tightening. No execution. |
| `help` | Display this skill's purpose, available skills summary, and invocation examples |

## Free-text intake contract

When the user invokes `@ai-director` with natural language, follow this write/structure/format/channel discipline so the request is always turned into the correct skill invocation and recorded in project memory.

### 1. Capture
- Preserve the user's exact wording (quote it in `{HANDOFF}`).
- Do not silently rewrite the goal into a different skill than the intent demands.

### 2. Load context
- Read `{HANDOFF}` and `{ITERATION_CARRIER}` before classifying.
- If either file is missing, treat as bootstrap state and note it.

### 3. Classify (intent → bucket)
- Match by intent, not keyword. Use the bucket table in § Orchestration protocol.
- If the intent clearly belongs to another framework (UI, business, social) or spans multiple frameworks, route to `@x-director` — it resolves sibling frameworks and channels to the correct director.
- If the intent is unclear, run a short probe (max 3 clarifying questions) or route to `@process-router` / `@plan-foundation probe`.
- **Score routing confidence** (`high` | `med` | `low`) based on signal strength (exact signal match vs partial vs fallback bucket). Carry this value into the record at step 6.

### 4. Channel (bucket → skill chain)
- Map the bucket to the exact skill chain from § Route / Shortcut chains.
- Check `SKILL_DEPENDENCIES.md` gates before invoking each skill.
- Use canonical invocation syntax: `@<skill-id> <mode> - <argument>` with ASCII hyphen `-`.

### 5. Confirm gate (before any skill invoke)

Render a **routing plan** and get explicit ack. Do **not** invoke any skill or write `{HANDOFF}` before ack.

```markdown
## ai-director routing plan
**Request:** "<user's verbatim request>"
**Classified bucket:** <bucket-name>
**Routing confidence:** high | med | low
**Will execute:**
1. @<skill> <mode> - <arg> → <expected outcome one-liner>
2. ...
**Non-reversible writes:** <list of HANDOFF / NEXT / SPEC / migration / plan files about to be created or modified, or "none (dry-run)">
Reply `y` / `yes` to proceed, `n` to abort, or edit the plan above.
```

End the gate with the Operator handoff close (Form B with the plan approval under `**Needs your approval:**` + one `**Next step:**` command) per SKILL_DEPENDENCIES.md.

**Trust mode (`-y`):** skip the gate. **Dry-run (`--dry-run`):** render the plan, write nothing, stop.
**Confidence `low` with no user ack within the call:** do not execute — ask one clarifying question instead.
**Cross-framework redirect:** if classification yields `not-.ai` or `cross-framework`, redirect to `@x-director` — it resolves sibling frameworks, runs preflight, and channels to the correct director. No `.ai` skill is invoked.

### 6. Structure/format the record
After the workflow completes or changes state, append to `{HANDOFF}` using this exact shape:

```markdown
## Latest action (@ai-director)
**Date:** YYYY-MM-DD
**Request:** "<user's original request>"
**Classified bucket:** <bucket-name>
**Routing confidence:** high | med | low
**Executed:**
1. @<skill> <mode> - <arg> → <result>
2. ...
**User correction:** <none | "free-text of what rerouted the chain and why">
**Blockers:** <any unresolved items | none>
**Next recommended:** @<skill> <mode> - <arg>
```

Also update `{ITERATION_CARRIER}` § **Recommended next** when the build cycle advances.

**Feedback loop:** the `Routing confidence` and `User correction` fields feed the `review-routing` mode. Even if a routing plan aborts (user said `n` at the Confirm gate), still write a record with `Executed: aborted at confirm gate` plus the correction note — that is signal the bucket table needs tightening.

## Orchestration protocol

When user says `@ai-director - <anything>`:

### 1. PARSE & CLASSIFY

Read `{HANDOFF}` and `{ITERATION_CARRIER}` for context. Classify the request into one of the following buckets. Match by intent, not keywords.

| Bucket | Signals | Lead skill |
|--------|---------|------------|
| `bootstrap` | "start project", "set up", "first time", ".work missing" | `project-bootstrap` |
| `foundation` | "blueprint", "understand project", "foundation docs", "create P0-P6" | `plan-foundation greenfield` |
| `foundation-probe` | "vague scope", "uncertain requirements", "understand the domain" | `plan-foundation probe` |
| `foundation-certify` | "check if ready", "certify plan-master-ready" | `plan-foundation certify` |
| `master-plan` | "master plan", "implementation plan", "roadmap", "milestones" | `plan-master greenfield` / `continue` |
| `master-probe` | "is the plan complete?", "check plan gaps", "probe the plan" | `plan-master probe` |
| `plan-verify` | "audit plan", "check alignment", "brownfield scan", "plan review" | `plan-verify` (foundation/master/alignment/brownfield) |
| `plan-repair` | "fix plan gaps", "brownfield synthesis", "repair foundation/master" | `plan-repair` |
| `session-control` | "start session", "close session", "commit", "where am I?" | `session-control` |
| `code-implementation` | "start coding", "build the feature", "implement M1", "continue iteration" | `code-implementation` |
| `code-verify` | "check code", "verify milestone", "audit uncommitted", "pre-commit check" | `code-verify` |
| `code-repair` | "fix findings", "repair code issues", "remediate" | `code-repair` |
| `feature-spec` | "new feature idea", "spec out a feature", "intake a request", "feature SPEC" | `feature-spec` |
| `feature-spec-create` | "create a SPEC for X", "new SPEC", "author SPEC" | `feature-spec create` |
| `concept` | "run MOD prompt", "architecture check", "NFR concept" | `concept-run` |
| `db-migration` | "schema change", "migration", "new table", "alter column" | `db-migration` |
| `dev-stack` | "Docker setup", "dev environment", "compose config" | `dev-stack` |
| `tauri-development` | "Tauri", "desktop app", "IPC setup", "shell strategy", "webview config", "bridge server" | `tauri-development` |
| `process-router` | "how do I...?", "where is...?", "what skill...?" | `process-router` |
| `deploy` | "deploy framework to another project", "copy to repo" | `deploy-files` / `deploy-basic` |
| `docs` | "document", "guide", "tutorial", "how-to", "write docs", "user guide", "create docs" | `@docs` |
| `feature-doc` | "document this feature", "brownfield feature doc", "existing feature docs", "catalog feature" | `@feature-spec document - <slug>` |
| `not-.ai` | Belongs to another framework: UI, design, frontend, business, strategy, social, community, etc. | Route to `@x-director` — it resolves sibling frameworks and channels to the correct director |
| `cross-framework` | Spans `.ai` + one or more other frameworks (e.g. "build a backend API and a UI for it") | Route to `@x-director` for coordination |
| `new-skill-needed` | No existing `.ai` skill can fulfill the request | Create new `.ai` skill, or `@x-director` if it belongs to another framework |
| `unsure` | Cannot classify, or user request is underspecified | `@plan-foundation probe` (adaptive questioning to narrow scope); or `@process-router` for "how do I…?" |

### 2. ROUTE

Map the classified bucket to the correct skill chain. Respect the dependency graph (SKILL_DEPENDENCIES.md). If a prerequisite is not met, report the gate and run the prerequisite first.

**Typical full flow (greenfield):**
```
@project-bootstrap init
  → @plan-foundation greenfield
    → @plan-foundation certify plan-master-ready
      → @plan-master greenfield
        → @plan-master status
          → @session-control start
            → @code-implementation plan - M1
              → @code-implementation start
                → @code-implementation continue (loop)
                  → @code-verify milestone
                    → @code-implementation complete
                      → @session-control close
```

**Shortcut chains (common requests):**

| User says | Execute |
|-----------|---------|
| "Start a new project" | `@project-bootstrap init` → `@plan-foundation greenfield` |
| "I need to understand the project requirements" | `@plan-foundation probe` |
| "Create a master implementation plan" | Check plan-master-ready. If yes → `@plan-master greenfield`. If no → `@plan-foundation certify` first. |
| "Is the plan ready for coding?" | `@plan-master status` → if implementation-ready: yes, route to code. If no, report gaps. |
| "Start building feature X" | `@code-implementation status` → if no active iteration → `@code-implementation plan - M{N}` → start |
| "Check the code before commit" | `@code-verify uncommitted` |
| "I need a database migration for users table" | `@db-migration status` → if init needed → `@db-migration init` → `@db-migration create - add users table` |
| "Audit the whole project plan" | `@plan-verify foundation` → `@plan-verify master` → `@plan-verify alignment` |
| "Fix the plan gaps from the audit" | `@plan-repair repair - from <mode>` matching the verify results |
| "Run the architecture prompts" | `@concept-run list` → recommended MOD prompts → run |
| "Tauri development guidance" | `@tauri-development` |
| "How do I start an iteration?" | `@process-router - how do I start an iteration?` |
| "Deploy Agent OS to my other project" | `@deploy-files copy - <path>` (fat-client) or `@deploy-basic - <path>` (thin-client) |
| "Write a guide / tutorial / reference doc" | `@docs create guide - <slug>` or `@docs create tutorial - <slug>` or `@docs create reference - <slug>` |
| "Document features, guides, and tutorials" | `@feature-spec status` → `@feature-spec document - <slug>` per feature + `@docs create guide - <slug>` per guide + `@docs create tutorial - <slug>` per tutorial |
| "Complete feature definitions (brownfield)" | `@feature-spec status` → `@feature-spec document - <slug>` for each undocumented feature |
| "Document this feature (brownfield)" | `@feature-spec document - <slug>` |
| "I need a UI for the login feature" | Route to `@x-director - I need a UI for the login feature` (cross-framework routing) |
| "Create a business strategy" | Route to `@x-director - Create a business strategy` (cross-framework routing) |
| "Set up a community forum" | Route to `@x-director - Set up a community forum` (cross-framework routing) |

### 3. CONFIRM GATE

Render the routing plan per § Free-text intake contract step 5. Obtain ack (`y`/`yes`) unless `-y` was passed. `--dry-run` renders and stops. Confidence `low` with no ack → ask one clarifying question instead of executing.

### 4. EXECUTE

For each skill in the chain:
1. Read the skill's `skill.md` to verify correct mode invocation.
2. Invoke the skill with proper syntax (`@<skill-id> <mode> - <args>`).
3. Verify the skill's completion checklist or gate passed before proceeding to the next step.
4. If a skill reports a gap or blocker, route to the corrective skill (e.g. `probe`, `plan`, `create`) — do not skip.
5. If the user redirects mid-flow (corrects the route), record the correction under `User correction` in step 5 RECORD; do not silently switch.

### 5. RECORD

After completing the workflow (or on any meaningful state change — including abort at the Confirm gate), update `{HANDOFF}`:

```markdown
## Latest action (@ai-director)
**Date:** YYYY-MM-DD
**Request:** "<user's original request>"
**Classified bucket:** <bucket-name>
**Routing confidence:** high | med | low
**Executed:**
1. @<skill> <mode> - <arg> → <result>
2. ...
**User correction:** <none | "free-text of what rerouted the chain and why">
**Blockers:** <any unresolved items>
**Next recommended:** @<skill> <mode> - <arg>
```

Also update `{ITERATION_CARRIER}` § Recommended next if the workflow advanced the build cycle.

## review-routing mode (feedback loop)

**Read-only.** Aggregates signal from recent `{HANDOFF}` entries to find buckets whose signal tables need tightening. Use after sessions where the operator redirected the chain or where `Routing confidence: low` recurs.

### Protocol

1. Read `{HANDOFF}`. Collect the last N (default 20) `## Latest action (@ai-director)` blocks.
2. For each block, extract: `Classified bucket`, `Routing confidence`, `User correction`, and whether `Executed` starts with `aborted at confirm gate`.
3. Group by bucket. Compute per bucket:
   - count of `low` confidence entries,
   - count of non-empty `User correction` entries,
   - count of aborts at the Confirm gate.
4. Output a read-only report:

```markdown
## ai-director review-routing

| Bucket | Entries | Low-conf | Corrections | Aborts | Signal-table verdict |
|--------|---------|----------|-------------|--------|----------------------|
| <bucket> | N | n | n | n | tighten / ok / split |
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md. Any `tighten`/`split` change request the operator must approve must ALSO appear in the closing handoff block (enumerated, with `path:line`), not only in the verdict table.

**Verdict rules:** `tighten` if corrections ≥ 2 or low-conf ≥ 3; `split` if corrections diverge (operators redirect the same bucket to two different skills); `ok` otherwise.

5. For each `tighten` / `split` row, list the specific signal strings in § Orchestration protocol § 1 bucket table to revise (quote 1-2 example `User correction` lines as evidence). **Do not edit the bucket table from this mode** — surface the change request; the operator or `@ai-director - <request>` decides.
6. No file writes. Update no HANDOFF. This mode never executes skills.

### Completion checklist

| # | Check |
|---|-------|
| 1 | Last N HANDOFF entries read |
| 2 | Per-bucket counts computed |
| 3 | Verdict assigned per rules |
| 4 | No file writes |
| 5 | Suggested bucket-table changes listed, not applied |

End the checklist response with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

---

## New skill protocol

If the user request genuinely cannot be fulfilled by any registered `.ai` skill, and falls outside the "Redirect to UI/Biz" rules:

1. **Confirm gap:** Check `skills/README.md` and ensure no existing skill or standard covers the need.
2. **Report:** Tell the user what skill is needed, why existing skills cannot cover it, and propose a name following the naming protocol (`{domain}-{role}`, kebab-case).
3. **Create** the new skill folder and `skill.md` following the established pattern (YAML frontmatter with `name` and `description`, Modes table, Prerequisites, Hard rules, Completion checklist).
4. **Register** the skill in `skills/README.md` table, `SKILL_DEPENDENCIES.md` dependency matrix, and `.cursorrules` § Skills table.
5. **Verify** the registration consistency.

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

**Do not create a new skill when:**
- The request maps to an existing skill or standard
- The request belongs to another framework (route to `@x-director`)
- The request can be handled by a probe loop, a concept prompt, or a process router query

## Prerequisites

- `.ai/` framework present with valid `skills/README.md` registry
- `{HANDOFF}` readable (may be empty/bootstrap state)
- `{ITERATION_CARRIER}` readable (may be empty/bootstrap state)

## Completion checklist

| # | Check |
|---|-------|
| 1 | User request classified correctly |
| 2 | Non-`.ai` requests channelled to `@x-director` (not routed directly) |
| 3 | Confirm gate rendered and ack obtained (or `-y` / `--dry-run` honoured) |
| 4 | Prerequisites met for each skill in chain (gates respected) |
| 5 | All skills invoked with correct mode syntax |
| 6 | Blockers/gaps reported and routed (not silently skipped) |
| 7 | `{HANDOFF}` updated with action summary including `Routing confidence` + `User correction` |
| 8 | `{ITERATION_CARRIER}` § Recommended next updated if applicable |
| 9 | New skill registered properly (if created) |

End the checklist response with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

## See also

- [`reference.md`](reference.md) — Full skill registry with modes, gates, and orchestration tables
- [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) — Gate/dependency matrix
- [`skills/README.md`](../README.md) — Skill registry table
- [`START_HERE.md`](../../START_HERE.md) — Operator decision tree
- [`PROCESS_ROUTER.md`](../../PROCESS_ROUTER.md) — Process router guide
- [`probe-protocol.md`](../probe-protocol.md) — Shared probe engine
- [`README.md`](../../README.md) — Agent OS overview
