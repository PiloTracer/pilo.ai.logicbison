# plan-repair - reference

Supplement to `skill.md`. Invocation examples and source-mode mapping.

---

## Invocation examples

### After plan-verify failure

```text
@plan-verify foundation
@plan-repair repair - from foundation
```

```text
@plan-verify master
@plan-repair repair - from master
```

```text
@plan-verify alignment
@plan-repair repair - from alignment
@plan-repair repair - from coverage
```

### Explicit goal (open language)

Free-text requests decompose into a **Framework alignment map** (R0-free in `skill.md`) before the F* table. The map identifies which `.ai` standards, concepts, SPECs, and docs each phrase implicates.

```text
@plan-repair foundation - we will require multi-tenant row-level security in v1
@plan-repair master - adjust M2 to split observability from domain API tasks
@plan-repair repair - master - add FR18 for export audit trail
```

**Alignment flow (free requests):**

```text
1. Free request (open language, goal text after -)
2. R0-free: Framework alignment map → standards, concepts, SPECs, foundation/master docs
3. F* table with Framework ref column
4. Repair plan cross-checked against alignment map
5. Delegate commands to upstream skills
6. Mandatory re-verify
```

When the request maps cleanly to framework components, the `Framework ref` column connects each F* row to the target standard, concept id, or plan section.

### Brownfield (no formal plan-foundation / plan-master — framework align)

Synthesizes `.work/plans/` from README, code, ROADMAP, ADRs. Does **not** require prior `@plan-foundation greenfield`.

```text
@plan-verify brownfield
@plan-repair brownfield
@plan-verify brownfield

@plan-repair brownfield - foundation    # foundation slots only
@plan-repair brownfield - master        # master + minimal foundation
```

### Default / status

```text
@plan-repair
@plan-repair repair
@plan-repair status
```

### Custom brief

```text
@plan-repair repair - custom - fix doc 04 bounded context list to match apis/ folders; update DIRECTORY_MAP
```

---

## Source → re-verify map

| Invocation | Run first (if no report) | Re-run after fix |
|------------|--------------------------|------------------|
| `from foundation` / `foundation` | `@plan-verify foundation` | `@plan-verify foundation` |
| `from master` / `master` | `@plan-verify master` | `@plan-verify master` |
| `from alignment` | `@plan-verify alignment` | `@plan-verify alignment` |
| `brownfield` | `@plan-verify status` | `@plan-verify foundation` (+ `master` when ready) |
| `custom` | (brief) | Modes in brief + minimum one verify pass |

---

## Delegate commands (quick reference)

| Need | Command |
|------|---------|
| Resume foundation phase | `@plan-foundation continue` |
| Certify for master plan | `@plan-foundation certify plan-master-ready` |
| New master plan | `@plan-master greenfield` |
| Resume draft master plan | `@plan-master continue` |
| Structured master delta | `@plan-master revise - <reason>` |
| Integrity re-check | `@plan-master integrity` |
| Regenerate NEXT block | `@code-implementation plan - M{N}` |
| Scaffold `.work/` | `@project-bootstrap init` |

---

## plan-repair vs upstream skills

| Situation | Use |
|-----------|-----|
| Single phase gate during greenfield | `@plan-foundation continue` (direct) |
| Multi-gap verify fail report | `@plan-repair repair - from foundation` |
| One clear master plan change | `@plan-master revise - …` or `@plan-repair master - …` (repair coordinates + re-verify) |
| Repo has code, no foundation 01–04 | `@plan-repair brownfield - foundation` |
| Test/lint fail | `@code-repair` (not plan-repair) |

---

## Wrong prompts

| Prompt | Problem | Use instead |
|--------|---------|-------------|
| `@plan-repair` with no findings or goal | No F* table | `@plan-verify` first or paste report |
| **repaired** without verify | Violates skill | R4 mandatory |
| Fix pytest failure | Wrong layer | `@code-repair` |
| Skip certify before master greenfield | PG1 blocked | `@plan-foundation certify` |
| Free request without R0-free alignment map | No framework traceability | Decompose into R0-free before F* table; label Framework ref per finding |
---

## Repair protocol R0–R5 (detailed)

<a id="repair-protocol-r0-r5"></a>

### R0 - Findings intake (mandatory)

| ID | Source | Severity | Finding | Affected paths | Fix strategy | Framework ref |
|----|--------|----------|---------|----------------|--------------|---------------|
| F1 | plan-verify foundation | fail | … | … | foundation continue / new doc | `—` (verify-sourced) |

`Framework ref` is populated when findings come from **open language** (custom brief, goal text after `-`) or **brownfield** discovery. Sources from `@plan-verify` reports (foundation / master / alignment) may leave it `—` (verify-sourced) since the verify report already frames findings in framework terms. Must cite at least one: standard, concept MOD id, foundation doc id, SPEC path, master plan §, or registry.

**Obtain findings by:**

1. Chat verify report,
2. **Run** `@plan-verify <mode>` now,
3. User goal after `-` (decompose into F* rows),
4. **Brownfield** discovery table (missing artifacts).

### R0-free - Framework alignment (free lang requests only)

**When:** Findings source is **custom** brief, goal text after `-`, or implicit layer resolution (no verifying report in chat). **Skip** when all F* rows come from a `@plan-verify` or `@db-migration verify` report.

Produce a **Framework alignment map** before the F* triage. This decomposes the free text into `.ai` framework components and ensures the repair stays within framework-consistent paths.

```markdown
### Free request → Framework alignment

**Request:** <paraphrase one line>

| Aspect | Framework component | Artifact path | Action |
|--------|---------------------|---------------|--------|
| <quote/phrase from request> | P0 scope | foundation/*-01-*-scope.md | Add/amend scope statement |
| <…> | FEATURE_STANDARD | .work/standards/*FEATURE_STANDARD* | SPEC needed / amend |
| <…> | CONVENTIONS | .work/standards/*CONVENTIONS* | Naming / layout check |
| <…> | threat-model | .work/standards/*threat-model* | Review surface |
| <…> | MOD-06 | .ai/concepts/ai-amplification/ | Trigger if agent authors plan/docs |
| <…> | P4 cross-cutting | .work/standards/*observability-spec* | Observable from day 1? |
| <…> | ADR | .work/decisions/ | Capture decision |
| <…> | Master plan §19 | .work/plans/full/*-full-plan.md | FR / task delta |
```

**Rules:**
- Minimum 1 component row per distinct framework aspect; omit rows with no plausible connection.
- **Inference** rule: when mapping is probabilistic (e.g. "SSO might need a SPEC"), label the row **Inference** and propose it — do not assume it.
- Cross-reference OPEN OWNER ACTIONS in `{HANDOFF}`; freeze the map before filing F* rows.
- Update the map if triage surfaces new framework connections.

**Triage:**

| Disposition | Action |
|-------------|--------|
| **fix-now** | Agent edits plan docs via upstream skill protocols; must cite Framework ref column |
| **owner** | `UNKNOWNS.md` or HANDOFF § Open owner actions; preserve Framework ref |
| **waiver** | HANDOFF or same-message user approval; note Framework ref |
| **redirect** | Code gap → `@code-repair`; session → `@session-control` |

If **>50%** rows are **owner** without documentation-only request → stop and list owner actions.

### R1 - Context load (mandatory)

| # | Path | When |
|---|------|------|
| 1 | `.cursorrules` | always |
| 2 | `{HANDOFF}` | always |
| 3 | `{ITERATION_CARRIER}` | alignment / master touches iteration |
| 4 | `{PLANS_ROOT}/foundation/*` | foundation |
| 5 | `{PLANS_ROOT}/full/*-full-plan.md` | master |
| 6 | `{PLANS_ROOT}/ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md` | always |
| 7 | `.ai/standards/20260519-MASTER_PLAN_STANDARD.md` | master |
| 8 | Relevant SPECs / ADRs | per F* paths |

Short **assumption ledger** when behavior is inferred from code-only brownfield repos.

### R2 - Repair plan (before edits)

≤15 lines: F* order (sorted by Framework ref → priority), delegate commands (`@plan-foundation continue`, `@plan-master revise - …`), files to create, re-verify mode for R4.

**Fix order:** blockers (bootstrap/HANDOFF) → foundation gates → master plan → alignment (NEXT) → registries.

When an **[R0-free](#r0-free---framework-alignment-free-lang-requests-only)** alignment map was produced, cross-check each repair item against the map's **Framework component** column — a repair that touches a standard must cite that standard path; a repair that alters scope must trace to foundation doc 01.

### R3 - Apply fixes (delegate)

| Layer | Primary delegate | When |
|-------|------------------|------|
| Foundation gaps | `@plan-foundation continue` | Partial P0–P6 |
| New product scope in foundation | Update doc 01 + registries; amend SPECs via `@feature-spec amend` | F* cites scope |
| Certify unlock | `@plan-foundation certify plan-master-ready` | After foundation-complete |
| Master delta | `@plan-master revise - <reason>` | Approved or Draft plan exists |
| New master plan | `@plan-master greenfield` or `continue` | No plan / partial Draft |
| Integrity fail | Fix cited contradictions → `@plan-master integrity` | Before certify/approve |
| NEXT drift only | `@code-implementation plan - M{N}` | After master is truth |
| Missing `.work/` skeleton | `@project-bootstrap init` | Brownfield |

**User goal text** (e.g. `foundation - we will require …`) must appear in:

- Foundation doc 01 scope / assumption ledger, **or**
- New/amended SPEC + ADR as appropriate, **or**
- Master plan FR row + §19 tasks after `@plan-master revise`

Record **Correction YYYY-MM-DD:** notes when editing Approved plans (per fix-existing-plans tutorial).

### R4 - Re-verify (mandatory)

| Repair source | Re-run after fixes |
|---------------|-------------------|
| **from foundation** / **foundation** | `@plan-verify foundation` |
| **from master** / **master** | `@plan-verify master` |
| **from alignment** | `@plan-verify alignment` |
| **custom** | Modes named in brief; minimum one `@plan-verify` pass |
| **brownfield** | `@plan-verify foundation` then `@plan-verify master` when applicable |

**Verdict:**

| Verdict | Meaning |
|---------|---------|
| **repaired** | Re-verify **pass** or **pass with gaps** (waivers documented) |
| **partial** | Some F* fixed; re-verify still **fail** |
| **failed** | Could not fix |
| **nothing to repair** | No findings |

### R5 - Repair report (mandatory)

```markdown
## plan-repair - <foundation | master | alignment | brownfield> - <verdict>

**Date:** <ISO>

### Findings
| ID | Disposition | Status | Evidence | Framework ref |
|----|-------------|--------|----------|---------------|

### Framework alignment (if R0-free ran)
<insert R0-free map or link to it>

### Delegated commands run
- `@plan-foundation …` / `@plan-master …` / `@code-implementation plan - M{N}`

### Completion checklist
| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | R0 findings intake | pass/fail | |
| 2 | R0-free alignment map (when free lang) | pass/skip | |
| 3 | R1 context load | pass/fail | |
| 4 | R2 repair plan (cross-checked vs alignment) | pass/fail | |
| 5 | R3 fixes applied; goal text in target artifacts | pass/fail | |
| 6 | R4 re-verify | pass/fail | |
| 7 | No plan ↔ code layer confusion | pass | |

### Remaining / owner
<list or none>

### Next
@plan-verify <mode> | @plan-foundation certify | @plan-master status | @code-implementation plan - M{N}
```

Any operator-required approval or question (e.g. **Remaining / owner** items, waivers, Inference confirmations) must ALSO appear in the closing handoff block (enumerated, with `path:line`), not only in the report body. End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.
---

## Brownfield repair protocol (detailed)

<a id="brownfield-repair-protocol"></a>

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

Any operator-required approval or decision in **Formal path remaining** must ALSO appear in the closing handoff block (enumerated, with `path:line`), not only in this section.
