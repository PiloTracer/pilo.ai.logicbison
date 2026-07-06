---
name: plan-repair
description: >-
  Remediate planning gaps from plan-verify, brownfield adoption (no prior formal
  plan-foundation or plan-master), or explicit change requests. Synthesizes and
  aligns .work/ artifacts to the .ai framework from repo evidence; may delegate
  to plan-foundation continue or plan-master revise when formal paths apply.
  Use plan-repair foundation, master, brownfield, or open-language plan fixes.
---

# plan-repair

Remediation layer for **planning documentation**. **Implements plan fixes**; does not replace detection (`plan-verify`) or application code repair (`code-repair`).

**Pairs with:** `plan-verify` (findings + mandatory re-verify), `plan-foundation`, `plan-master`, `code-implementation` (regenerate iteration after master repair), `feature-spec`, `session-control`, `.cursorrules`.

**Canonical path:** `.ai/skills/plan-repair/skill.md` · **Invocation examples:** `reference.md`

**Registry:** [`.ai/skills/SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md).

**Hard rules:**

- **Findings in, evidence out** — start from F* rows (verify report, fresh `@plan-verify`, or decomposed user brief). No plan edits without documented findings or an explicit same-message goal.
- **Re-verify mandatory** — after repairs, re-run the **same** `@plan-verify` mode that sourced the findings ([R4](#r4--re-verify-mandatory)).
- **Delegate mutating upstream work** — follow `plan-foundation` / `plan-master` protocols for continue, certify, greenfield, revise; plan-repair **coordinates** and records deltas, it does not invent alternate plan formats.
- **Brownfield allowed** — may **create or align** planning artifacts when `@plan-foundation` / `@plan-master` were **never run formally**; synthesize from README, code, ADRs, ROADMAP, issues. Formal gates (certify, Approved) are **targets**, not blockers for starting repair ([Brownfield repair](#brownfield-repair-protocol)).
- **Synthesis headers** — files created in brownfield mode must include `**Brownfield synthesis YYYY-MM-DD:**` and label inferred content **Inference** until owner confirms.
- **No application code** unless the user explicitly requests implementation in the same message.
- **No secrets** in plan prose; no PII in examples.
- Does **not** own HANDOFF/NEXT bookends unless the user asks (route to `session-control`).
- Every **repair** ends with a **Completion checklist** — `pass` | `fail` | `skip` with evidence.

---

## Parse invocation

Normalize to **mode** + optional **source** or **goal text** (after `-`). ASCII hyphen only.

| User says | Mode | Action |
|-----------|------|--------|
| `@plan-repair` | repair | [Repair protocol](#repair-protocol) — infer target |
| `@plan-repair` **repair** | repair | Same |
| `@plan-repair` **foundation** | repair (foundation) | [Foundation repair](#foundation-repair) |
| `@plan-repair` **repair** - **foundation** - \<goal\> | repair (foundation) | Foundation repair with stated delta |
| `@plan-repair` **master** | repair (master) | [Master repair](#master-repair) |
| `@plan-repair` **repair** - **master** - \<goal\> | repair (master) | Master repair with stated delta |
| `@plan-repair` **repair** - **from** **foundation** | repair (foundation) | Findings from `@plan-verify foundation` |
| `@plan-repair` **repair** - **from** **master** | repair (master) | Findings from `@plan-verify master` |
| `@plan-repair` **repair** - **from** **alignment** | repair (alignment) | Findings from `@plan-verify alignment` |
| `@plan-repair` **repair** - **from** **coverage** | repair (coverage) | Findings from `@plan-verify coverage` |
| `@plan-repair` **repair** - **custom** - \<brief\> | repair | User brief → F* table → targeted layer |
| `@plan-repair` **brownfield** | brownfield | [Brownfield bootstrap](#brownfield-bootstrap) |
| `@plan-repair` **brownfield** - **foundation** | brownfield | Scaffold + foundation artifacts |
| `@plan-repair` **brownfield** - **master** | brownfield | Foundation gate + master plan bootstrap |
| `@plan-repair` **fix** - … | repair | Alias for **repair** |
| `@plan-repair` **status** | status | [Status protocol](#status-protocol) — read-only |

**Open language examples (map to rows above):**

```text
@plan-repair foundation - we will require SSO for all desk users
@plan-repair master - adjust M3 to add observability tasks before domain APIs
@plan-repair - fix foundation so we can certify plan-master-ready
```

**Free request → framework alignment:** When findings are sourced from **open language** (custom brief, goal text after `-`, or implicit layer resolution), run **[R0-free](#r0-free---framework-alignment-free-lang-requests-only)** before triage. This decomposes the free text into a **Framework alignment map** — identifying which `.ai` concepts, standards, SPECs, foundation/master docs, and registries the request implicates. The map feeds F* rows (each gains a `Framework ref` column) and constrains the R2 repair plan to framework-consistent delegate targets.

**Default target when omitted:**

1. Latest **fail** from `@plan-verify` in the last 3 assistant turns → matching **from** mode.
2. Else if user message names **foundation** / **master** / **alignment** / **NEXT** / **full plan** → that layer.
3. Else if `{PLANS_ROOT}/foundation/` incomplete → **foundation**.
4. Else if no `*-full-plan.md` → **master** (if plan-master-ready) else **foundation**.
5. Else if repo has code or legacy docs → **brownfield**.
6. Else ask once: **Q:** Repair foundation, master plan, alignment, or brownfield (full framework align)?

**Brownfield default:** When BF0 = yes (see `plan-verify` § Brownfield detection) and user did not name a layer → `@plan-repair brownfield` (full align pass).

---

## Repair protocol

### R0 - Findings intake (mandatory)

Build F* table from verify report, chat, user goal, or brownfield discovery. Full table schema and sources: [reference.md § Repair protocol R0–R5 (detailed)](reference.md#repair-protocol-r0-r5-detailed) (R0).

### R0-free - Framework alignment (free lang requests only)

When findings are from custom brief (not verify report): produce Framework alignment map before F* triage. Template and triage table: [reference.md § Repair protocol R0–R5 (detailed)](reference.md#repair-protocol-r0-r5-detailed) (R0-free).

### R1 - Context load (mandatory)

Context read table by layer: [reference.md § Repair protocol R0–R5 (detailed)](reference.md#repair-protocol-r0-r5-detailed) (R1).

### R2 - Repair plan (before edits)

≤15-line plan; fix order; cross-check R0-free map: [reference.md § Repair protocol R0–R5 (detailed)](reference.md#repair-protocol-r0-r5-detailed) (R2).

### R3 - Apply fixes (delegate)

Delegate table (foundation, master, NEXT, bootstrap): [reference.md § Repair protocol R0–R5 (detailed)](reference.md#repair-protocol-r0-r5-detailed) (R3).

<a id="r4--re-verify-mandatory"></a>
### R4 - Re-verify (mandatory)

Re-verify mode by repair source; verdict table: [reference.md § Repair protocol R0–R5 (detailed)](reference.md#repair-protocol-r0-r5-detailed) (R4).

### R5 - Repair report (mandatory)

Report template and checklist: [reference.md § Repair protocol R0–R5 (detailed)](reference.md#repair-protocol-r0-r5-detailed) (R5).


---

## Foundation repair

**Triggers:** `@plan-repair foundation`, `repair - from foundation`, `repair - foundation - <goal>`, brownfield foundation path.

1. Run [R0–R2](#repair-protocol).
2. If `{HANDOFF}` or `.cursorrules` missing → `@project-bootstrap init` first ([blocked report](../SKILL_DEPENDENCIES.md#blocked-report-shape)).
3. Follow `@plan-foundation continue` for the **first phase not done**; produce missing artifacts (01–04, ADRs, SPECs, standards) per that skill's GATE checklists.
4. Apply **goal text** to doc 01 + sync `ASSUMPTIONS.md` / `RISK_REGISTRY.md` / `UNKNOWNS.md`.
5. At P3+ with contradictions → `@plan-master integrity` on foundation set.
6. When gates satisfied → offer `@plan-foundation certify plan-master-ready` (user may run in same session if asked).
7. [R4](#r4--re-verify-mandatory) → `@plan-verify foundation`.

**Brownfield (code exists, no formal plan-foundation run):**

- Enter [Brownfield repair protocol](#brownfield-repair-protocol) BR3 instead of blocking on empty phases.
- Do **not** force `@plan-foundation greenfield` questionnaire unless user requests it in the same message.

---

## Master repair

**Triggers:** `@plan-repair master`, `repair - master - <goal>`, `repair - from master`.

### MG1 - Plan-master-ready gate

| Condition | Action |
|-----------|--------|
| **plan-master-ready: yes** | Proceed to MG2 |
| **brownfield: yes** (BF0) | Proceed to MG2 via [BR4](#br4---synthesize-master-plan-no-prior-formal-plan-master); record HANDOFF waiver line; **do not** hard-stop |
| **plan-master-ready: no** and **brownfield: no** | Stop:

```markdown
## @plan-repair master - blocked (prerequisite)

**Required:** plan-master-ready: yes
**Detected:** plan-master-ready: no
**Run first:** `@plan-repair foundation` → `@plan-foundation certify plan-master-ready`
```

Or run **`@plan-repair brownfield`** to align without prior formal foundation.

### MG2 - Apply delta

| Situation | Delegate |
|-----------|----------|
| No `*-full-plan.md` | `@plan-master greenfield` **or** brownfield Draft synthesis ([BR4](#br4---synthesize-master-plan-no-prior-formal-plan-master)) |
| Draft partial plan | `@plan-master continue` |
| Approved or Draft update | `@plan-master revise - <goal from user or F*>` |
| Integrity-only failures | Fix cited sections → `@plan-master integrity` |

**Goal text** must flow into revise reason and plan Decision log / traceability matrix.

### MG3 - Post-repair

- If iteration exists and §19 tasks changed → `@code-implementation plan - M{N}`.
- [R4](#r4--re-verify-mandatory) → `@plan-verify master` (+ `@plan-verify alignment` if NEXT active).

---

## Alignment repair

**Triggers:** `repair - from alignment`, verify alignment **fail**.

**Order (minimize thrash — tutorial §6):**

1. Fix `{MASTER_PLAN}` if FR/task ids wrong → [Master repair](#master-repair).
2. Regenerate iteration → `@code-implementation plan - M{N}`.
3. SPEC amendments if behaviour contract wrong → `@feature-spec amend - <slug>`.
4. [R4](#r4--re-verify-mandatory) → `@plan-verify alignment`.

---

## Coverage repair

**Triggers:** `repair - from coverage`, `@plan-verify coverage` **fail** or **pass with gaps**, or user goal to register unmapped app surfaces.

**Objective:** Close gaps between application surfaces and `{FEATURE_SPEC_ROOT}` without inventing parallel registries (`feature.yml`, ad-hoc domain-registry files). Canon: FEATURE_STANDARD SPEC + DIRECTORY_MAP.

### CG0 - Intake

1. Run `@plan-verify coverage` **or** absorb a coverage report from chat (same session).
2. Build F* rows: one per **unmapped** surface (severity **High** for production routes/APIs; **Med** for cross-cutting shell/LMS-style clusters).

### CG1 - Remediate (per gap)

| Step | Action |
|------|--------|
| 1 | Pick kebab-case **slug** (`dashboard-shell`, `courses-lms`, …) — no collision with existing folder |
| 2 | `@feature-spec create - <slug>` — **Draft** SPEC; fill **Implementation map** with inventoried paths; Purpose one paragraph; §2 Out of scope explicit |
| 3 | Update DIRECTORY_MAP bounded-context / path rows to reference the slug |
| 4 | Add slug to `{FEATURE_SPEC_ROOT}/README.md` index (navigation list only — no duplicate path tables) |

**Do not** create `feature.yml` unless the user explicitly requires a legacy consumer; prefer SPEC **§14 Implementation map**.

### CG2 - Optional audit artifact

When user asked to persist the verify run, update `{WORK_ROOT}/reports/YYYYMMDD-code-registry-audit.md` **Resolved** rows for closed gaps.

### CG3 - Post-repair

[R4](#r4--re-verify-mandatory) → `@plan-verify coverage`.

If framework slots were also missing → `@plan-verify brownfield` after coverage **pass**.

---

## Brownfield repair protocol

**Triggers:** `@plan-repair brownfield`, `brownfield - foundation`, `brownfield - master`, BF0 = yes on any repair, or verify **brownfield-gap** / **fail** with brownfield header.

**Purpose:** Bring a **code-first or legacy-doc** repository to the **best possible alignment** with the `.ai` framework **without** requiring a prior formal `@plan-foundation greenfield` or `@plan-master greenfield` run. Formal certify/approve may come **after** alignment.

### BR0 - Brownfield detection

Use the same BF0 rules as `plan-verify` § Brownfield detection. If **brownfield: no** and user invoked `brownfield` only → run standard repair on named layer instead.

### BR1 - Assess (mandatory, no writes)

1. Run `@plan-verify brownfield` **or** execute BF1–BF3 inline (same slot map as plan-verify).
2. Build F* rows from gaps (missing slots, contradictions, substitute-only rows).
3. Present **Repair plan** (R2) listing files to **create** | **align** | **migrate** (legacy → canonical path).

### BR2 - Scaffold (minimal writes)

| Step | Action |
|------|--------|
| 1 | If `.work/` or `.cursorrules` missing → `@project-bootstrap init` with **`overwrite-missing`** (default; never `overwrite-all` without explicit user token) |
| 2 | Create empty registries from `plan-foundation` reference templates if missing |
| 3 | Update `{HANDOFF}` § Repository state with: `Brownfield-aligned: in progress` (date) — **do not** claim `Plan-master-ready` until certify passes |

### BR3 - Synthesize foundation (no greenfield questionnaire)

**Does not require** prior `@plan-foundation greenfield`. Prefer **evidence-backed synthesis** over empty templates.

| Artifact | Create when missing | Synthesis sources (priority order) |
|----------|---------------------|-----------------------------------|
| `foundation/…-01-…-initial-scope.md` | Always if no 01 | README, HANDOFF, product brief |
| `foundation/…-01-…-scope.md` | If no scope doc | initial-scope + issues/epics |
| `foundation/…-04-…` | If no doc 04 | Code tree, ADRs, DIRECTORY_MAP, package layout |
| `02` integration | If external APIs | `.work/docs/integration/`, code clients |
| `03` adjacency | If multi-product | README roadmap, module boundaries |
| ADRs | If `{DECISIONS_ROOT}` thin | Migrate `docs/adr/*` → `.work/decisions/` or index with links |
| SPECs | If contexts lack SPEC | `@feature-spec create - <slug>` from module + tests (**Inference** rules); or `@plan-verify coverage` → `repair - from coverage` |
| Standards | If missing | Copy from `.ai/standards/*.md` templates into `.work/standards/`; fill **Inference** from linter/tsconfig |
| Registries | If empty | Extract from TODOs, README risks, open issues |

**Execution style:**

- Use `@plan-foundation continue` **only** for phases where interactive answers are still needed; otherwise **write directly** per GATE artifact lists in `plan-foundation/skill.md`, marking synthesized sections.
- At end of foundation synthesis → `@plan-master integrity` on foundation set when ≥2 artifacts exist.
- **Optional formal path** (user may request later): `@plan-foundation certify plan-master-ready` — not required to finish brownfield repair.

### BR4 - Synthesize master plan (no prior formal plan-master)

**Does not require** `Plan-master-ready:` in HANDOFF **before** starting synthesis. **Does require** foundation slots ≥ **partial** (scope + architecture evidence).

| Situation | Action |
|-----------|--------|
| No `*-full-plan.md` | Create `{PLANS_ROOT}/full/YYYYMMDD-full-plan.md` **Draft** using `MASTER_PLAN_STANDARD` + evidence from ROADMAP, milestones, NEXT, code milestones |
| Substitute ROADMAP only | **Migrate** content into §19 task table with `M{N}-T{N}` ids; add FR/NFR stubs traced to README |
| Partial draft plan | `@plan-master continue` **or** direct edit + `@plan-master revise - brownfield alignment YYYY-MM-DD` |
| User goal after `-` | Apply as revise reason once base plan exists |

**PG1 brownfield waiver:** When creating the **first** master plan from synthesis, record in HANDOFF:

```text
Brownfield master synthesis: YYYY-MM-DD — formal plan-master-ready pending @plan-foundation certify
```

Then run `@plan-master greenfield` **only if** user wants full phase questionnaire; otherwise author Draft plan directly from [BR3](#br3---synthesize-foundation-no-greenfield-questionnaire) outputs + ROADMAP.

**implementation-ready:** Never set **yes** in brownfield repair — only **Draft** master until owner approves via plan-master workflow.

### BR5 - Synthesize alignment (NEXT)

| Situation | Action |
|-----------|--------|
| No valid `## Current iteration` | `@code-implementation plan - M{N}` when Approved/Draft plan has §19; else create minimal NEXT with **Recommended next** from synthesized M1 |
| NEXT predates framework | Rewrite block to cite `{MASTER_PLAN}` §19; preserve owner task intent in Notes |
| No milestone ids in legacy NEXT | Map tasks to new `M1-T1…` with trace row in repair report |

### BR6 - Close brownfield pass

1. Update `{HANDOFF}`: `Brownfield-aligned: YYYY-MM-DD` + list remaining formal gaps (certify, Approved).
2. Sync registries from new docs.
3. [R4](#r4--re-verify-mandatory): `@plan-verify brownfield` (required).
4. Verdict **repaired** when verify tier ≥ **brownfield-partial** and no High gaps without waiver.

### BR7 - Brownfield repair report addendum

Append to R5:

```markdown
### Brownfield manifest
| Path | Action | Source |
|------|--------|--------|
| … | created | README §… |

### Formal path remaining
- [ ] @plan-foundation certify plan-master-ready
- [ ] @plan-master continue → Approved
```

---

<a id="brownfield-bootstrap"></a>
## Brownfield bootstrap (alias)

`@plan-repair brownfield` = full [Brownfield repair protocol](#brownfield-repair-protocol).

`brownfield - foundation` → BR2–BR3 only, then `@plan-verify foundation` (BF branch).

`brownfield - master` → BR3 (minimal) + BR4, then `@plan-verify master` (BF branch).

---

## Status protocol

Read-only.

```markdown
## plan-repair status

**Brownfield:** yes | no
**Brownfield-aligned:** yes | no | in progress | unknown
**Foundation-complete:** yes | no | unknown (formal)
**Plan-master-ready:** yes | no | unknown (formal)
**Master plan:** <path | substitute | none>
**Suggested repair:** @plan-repair brownfield | foundation | master | brownfield - foundation
```

### BR0 - Brownfield detection

Same BF0 rules as `plan-verify` § Brownfield detection: [reference.md § Brownfield repair protocol (detailed)](reference.md#brownfield-repair-protocol) (BR0).

### BR1 - Assess (mandatory, no writes)

Run `@plan-verify brownfield` or BF1–BF3 inline; build F* rows; present R2 repair plan: [reference.md § Brownfield repair protocol (detailed)](reference.md#brownfield-repair-protocol) (BR1).

### BR2 - Scaffold (minimal writes)

Bootstrap + empty registries + HANDOFF brownfield line: [reference.md § Brownfield repair protocol (detailed)](reference.md#brownfield-repair-protocol) (BR2).

### BR3 - Synthesize foundation (no greenfield questionnaire)

Artifact synthesis table and execution style: [reference.md § Brownfield repair protocol (detailed)](reference.md#brownfield-repair-protocol) (BR3).

### BR4 - Synthesize master plan (no prior formal plan-master)

Draft plan from evidence; PG1 brownfield waiver line: [reference.md § Brownfield repair protocol (detailed)](reference.md#brownfield-repair-protocol) (BR4).

### BR5 - Synthesize alignment (NEXT)

Regenerate or rewrite iteration block: [reference.md § Brownfield repair protocol (detailed)](reference.md#brownfield-repair-protocol) (BR5).

### BR6 - Close brownfield pass

HANDOFF update, registries, R4 `@plan-verify brownfield`: [reference.md § Brownfield repair protocol (detailed)](reference.md#brownfield-repair-protocol) (BR6).

### BR7 - Brownfield repair report addendum

Brownfield manifest + formal path remaining checklist: [reference.md § Brownfield repair protocol (detailed)](reference.md#brownfield-repair-protocol) (BR7).

