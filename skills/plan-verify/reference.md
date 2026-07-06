# plan-verify - reference

Supplement to `skill.md`. Invocation examples and mode picker.

---

## Invocation examples

```text
@plan-verify brownfield               # full framework alignment (no prior formal plan-foundation/master)
@plan-verify foundation
@plan-verify master
@plan-verify alignment
@plan-verify coverage                 # app surfaces vs SPECs / DIRECTORY_MAP
@plan-verify registry                 # alias: coverage
@plan-verify drift                    # alias: alignment
@plan-verify status
@plan-verify                          # default: brownfield if code-first repo; else alignment / master / foundation
```

Open language (agent maps to mode; emits **Request interpretation** block before running):

```text
@plan-verify - audit foundation docs for plan-master-ready
@plan-verify - is our master plan ready for implementation?
@plan-verify - check NEXT against the full plan for M2
@plan-verify - align existing repo to Agent OS without plan-foundation greenfield
@plan-verify - find unmapped dashboard pages and API routes
@plan-verify coverage - audit code-to-feature registry before M2
```

**Interpretation flow (free requests):**

When the user does not provide an explicit mode keyword, the agent:
1. Detects keywords or intent from the free text
2. Maps to the closest framework mode (foundation, master, alignment, brownfield, status)
3. Emits a **Request interpretation** block showing the mapping before running the protocol
4. Labels the mapping **Confirmed** (unambiguous) or **Inference** (needs user confirmation)

The interpretation block appears in the verification report header. For explicit-mode invocations (e.g. `@plan-verify foundation`), the block records `explicit mode — no interpretation needed`.

---

## Brownfield (no formal plan-foundation / plan-master)

Use when the repo has **code or legacy docs** but never ran `@plan-foundation greenfield` or `@plan-master greenfield`.

```text
@plan-verify brownfield
@plan-repair brownfield
@plan-verify brownfield          # re-verify after repair
```

**Readiness labels (brownfield — not formal certify):**

| Label | Meaning |
|-------|---------|
| **brownfield-aligned** | ≥70% framework slots covered (canonical or substitute) |
| **brownfield-partial** | 40–69%; repair can continue |
| **formal-plan-master-ready** | Requires `@plan-foundation certify` — separate from brownfield-aligned |

---

## Mode picker

| Situation | Mode |
|-----------|------|
| Before `@plan-foundation certify` | **foundation** |
| Before `@plan-master greenfield` / after foundation change | **foundation** |
| Before approving master plan / broad coding | **master** |
| Before `@code-implementation complete` (plan slice) | **alignment** + **code-verify milestone** |
| NEXT tasks do not match plan §19 | **alignment** |
| Brownfield / legacy repo, no formal planning run | **brownfield** first |
| Brownfield repo, unknown planning state | **brownfield** → **foundation** → **master** → **alignment** |
| Quick "what should I verify?" | **status** |

---

## Typical flows

**Foundation not ready for master plan:**

```text
@plan-verify foundation
@plan-repair repair - from foundation
@plan-verify foundation
@plan-foundation certify plan-master-ready
```

**Master plan wrong or stale:**

```text
@plan-verify master
@plan-repair master - adjust checkout flow for guest users
@plan-verify master
```

**NEXT and full plan out of sync:**

```text
@plan-verify alignment
@plan-repair master - reconcile M2 task ids with FR12
@code-implementation plan - M2
@plan-verify alignment
```

**Brownfield adopt (code-first repo):**

```text
@plan-verify brownfield
@plan-repair brownfield
@plan-verify brownfield
# optional formal path later:
@plan-foundation certify plan-master-ready
@plan-master continue
```

**Verify then repair (symmetric to code layer):**

```text
@plan-verify foundation
# … fail …
@plan-repair repair - from foundation
```

---

## Mapping to legacy skill verbs

| plan-verify | Closest legacy |
|-------------|----------------|
| foundation | `@plan-foundation status` + `@plan-master integrity` (foundation scope) |
| master | `@plan-master status` + `@plan-master integrity` |
| alignment | Tutorial `20260518-tutorial-fix-existing-plans.md` |

plan-verify **does not replace** `certify`, `continue`, `greenfield`, or `revise` — it **audits** and routes to **plan-repair** or upstream skills.

---

## Wrong prompts

| Prompt | Problem | Use instead |
|--------|---------|-------------|
| `@plan-verify` then edit SPECs inline | Verify is read-only | `@plan-repair foundation - …` |
| Expect implementation-ready from foundation mode | Wrong layer | `@plan-verify master` |
| Fix code test failures | Wrong layer | `@code-verify` / `@code-repair` |
| Open-language verify without interpretation block | No framework traceability | Emit **Request interpretation** before protocol; label mapping Confirmed / Inference |
---

## Brownfield detection and verify (detailed)

<a id="brownfield-detection-verify"></a>

## Brownfield detection (BF0)

Run at the start of **every** mode. Record **brownfield: yes | no** in the report header.

**brownfield: yes** when **any** of:

| Signal | Evidence |
|--------|----------|
| No formal foundation run | `{HANDOFF}` lacks `Plan-master-ready:` **and** foundation doc 01–04 missing or stub-only |
| No formal master plan | No `{PLANS_ROOT}/full/*-full-plan.md` **or** plan is clearly pre-framework (no `M{N}-T{N}` ids, wrong layout) |
| Code-first repo | Application source tree exists (`REPLACE:APP_ROOT` or obvious `src/`, `apis/`, `backend/`) |
| User invoked brownfield | Message contains `brownfield`, `legacy`, `existing repo`, `never ran plan-foundation`, `align framework` |
| Legacy planning only | `ROADMAP.md`, `docs/planning/`, GitHub milestones, or README-only scope **without** `.work/plans/foundation/` |

**brownfield: no** when HANDOFF records `Plan-master-ready: <date>` **and** foundation 01–04 + registries exist per `plan-foundation` status.

**When brownfield: yes** — still run the requested mode, but follow the **BF branch** in that protocol (or use dedicated **brownfield** mode for all layers at once).

---

## Framework alignment map (brownfield)

Score each **canonical slot** against what exists on disk. Do not require formal P0–P6 completion to run checks.

| Slot | Canonical path (under repo root) | Acceptable brownfield substitutes (cite path) |
|------|----------------------------------|-----------------------------------------------|
| Agent rules | `.cursorrules` | Missing → gap (bootstrap) |
| HANDOFF | `.work/context/HANDOFF.md` | Missing → gap |
| P0 / scope capture | `.work/plans/foundation/*-01-*-initial-scope.md` | README § product, `docs/vision.md`, top of HANDOFF |
| Scope doc 01 | `.work/plans/foundation/*-01-*-scope.md` | Same + issue labels / epic docs |
| Architecture foundation 04 | `.work/plans/foundation/*-04-*` | ADR index, `docs/architecture.md`, DIRECTORY_MAP + code tree |
| ADRs | `.work/decisions/` | `docs/adr/`, inline README decisions |
| SPECs | `.work/features/*/…-SPEC.md` | Domain README, test names, module docstrings (infer **Inference**) |
| Standards | `standards/*CONVENTIONS*`, `*FEATURE_STANDARD*`, `*DIRECTORY_MAP*` | Repo conventions doc; infer from linter config |
| Registries | `.work/plans/ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md` | TODO/FIXME scan, issue tracker, empty template = gap |
| Master plan | `.work/plans/full/*-full-plan.md` | `ROADMAP.md`, milestone issues, dense NEXT only |
| Iteration | `.work/plans/NEXT.md` | Kanban export, sprint doc (partial credit) |
| Stack | `REPLACE:TECH_STACK_DOC` | `package.json`, `pyproject.toml`, `go.mod`, Dockerfile |

**Coverage score:** `present` | `substitute` | `partial` | `missing` per slot. **Framework alignment %** = (present + substitute) / total slots (round down; label **Estimate**).

---

## Brownfield verify protocol

**Triggers:** `@plan-verify brownfield`, or **BF0 = yes** on any mode.

**Objective:** Best-effort read-only assessment of how well the repo matches the `.ai` planning model **without** requiring prior `@plan-foundation greenfield` or `@plan-master greenfield`.

### BF1 - Repo discovery (mandatory)

1. Inventory per [Framework alignment map](#framework-alignment-map-brownfield).
2. Read: `README.md`, `{HANDOFF}` (if any), app tree (2 levels), `{DECISIONS_ROOT}/`, `{FEATURE_SPEC_ROOT}/`, existing plans under `{PLANS_ROOT}/`.
3. Build **assumption ledger**: label each inferred fact **Confirmed** (file cite) | **Inference** | **Unverified**.

### BF2 - Layer assessments (run all that apply)

| Layer | When | Action |
|-------|------|--------|
| Foundation | Always in brownfield | [Foundation verify](#foundation-verify-protocol) **BF branch** — matrix uses substitutes; skip F1 integrity **fail** on missing docs → record `integrity: skip - no foundation set to audit` |
| Master | Master plan or substitute exists | [Master verify](#master-verify-protocol) **BF branch** — conformance vs `MASTER_PLAN_STANDARD` on substitute or partial plan |
| Alignment | NEXT or sprint doc exists | [Alignment verify](#alignment-verify-protocol) **BF branch** — compare NEXT to best available roadmap (master plan **or** substitute) |

### BF3 - Formal readiness (report only — do not certify)

| Label | Meaning |
|-------|---------|
| **formal-foundation-complete** | Would be **yes** per `plan-foundation` gates (rare in brownfield) |
| **formal-plan-master-ready** | HANDOFF certify date or equivalent |
| **brownfield-aligned** | ≥70% framework slots `present` or `substitute`; no High-severity contradictions |
| **brownfield-partial** | 40–69% coverage or major substitutes only |
| **brownfield-gap** | <40% or blocking contradictions |

### BF4 - Brownfield report (mandatory)

```markdown
## plan-verify brownfield - <Project>

**Date:** <ISO> · **Brownfield:** yes
**Framework alignment:** <N>% (Estimate) · **Tier:** brownfield-aligned | brownfield-partial | brownfield-gap

### Request interpretation
<when open language — insert interpretation block; otherwise: explicit brownfield mode>

### Slot coverage
| Slot | Status | Source path | Notes |
|------|--------|-------------|-------|

### Formal readiness (not certified here)
- formal-foundation-complete: yes | no
- formal-plan-master-ready: yes | no
- brownfield-aligned: yes | no

### Layer verdicts
- Foundation: pass | pass with gaps | fail | skip
- Master: …
- Alignment: …

### High-priority gaps
<ordered>

### Verdict
**aligned-best-effort** | **pass with gaps** | **fail**

### Next step
@plan-repair brownfield | @plan-repair brownfield - foundation | @project-bootstrap init (overwrite-missing)
```

**Verdict rules (brownfield):**

- **aligned-best-effort** — brownfield-aligned **yes**; safe to proceed with documented waivers; recommend `@plan-repair brownfield` to close gaps without full greenfield questionnaire.
- **pass with gaps** — usable substitutes; formal certify still pending.
- **fail** — contradictions, missing `.work/` skeleton, or no product truth (cannot infer scope).
---

## Foundation verify protocol (detailed)

<a id="foundation-verify-protocol"></a>

## Foundation verify protocol

Cross-check **foundation layer** readiness: P0–P6 gates, registries, traceability, and semantic integrity on foundation artifacts.

### Foundation verify — brownfield branch (BF)

When **BF0 = yes**:

1. Run [BF1](#bf1---repo-discovery-mandatory) slot inventory for foundation rows only.
2. **Skip** hard fail when `plan-foundation status` would show all **not started** — instead score each P0–P6 row: **present** | **substitute** | **partial** | **missing** with substitute path.
3. Run `plan-master integrity` only if ≥2 foundation artifacts exist (01, 04, ADR, or SPEC); else **integrity: skip**.
4. Verdict may be **pass with gaps** or **aligned-best-effort** when substitutes cover scope + architecture; list **formal-foundation-complete: no** explicitly.
5. **Next step** defaults to `@plan-repair brownfield - foundation` (not `@plan-foundation greenfield` unless user wants full questionnaire).

### F0 - Invoke upstream status (mandatory)

Follow `.ai/skills/plan-foundation/skill.md` § **Status protocol** (S1–S6). Produce or absorb the standard **Foundation status** report.

Record in your working notes (do not conflate labels):

- **foundation-complete:** yes | no
- **plan-master-ready:** yes | no | not evaluated
- Phase table P0–P6 with evidence paths

### F1 - Integrity on foundation artifacts (mandatory)

Follow `.ai/skills/plan-master/skill.md` § **integrity** mode on **foundation set only** (docs 01–04, ADRs, SPECs, registries — no `*-full-plan.md` required).

Record: **integrity:** pass | pass with waivers | fail

### F2 - Foundation check matrix

| Dimension | Question | Result |
|-----------|----------|--------|
| P0 capture | P0 initial scope + `.cursorrules` + registries exist? | pass / fail / gap |
| P1 exploration | Docs 01–04 present; doc 04 is architecture foundation not master plan? | pass / fail / gap |
| P2 ADRs | Core ADRs Decided or deferred with UNKNOWNS? | pass / fail / gap |
| P3 SPECs | CONVENTIONS + FEATURE_STANDARD + DIRECTORY_MAP + ≥1 SPEC with R1…? | pass / fail / gap |
| P4 cross-cutting | Threat model, observability, stack doc when UI/security in scope? | pass / fail / skip |
| P5 infra | Proposal or HANDOFF waiver for compose? | pass / fail / skip |
| P6 ops | HANDOFF + NEXT + README gates? | pass / fail / gap |
| Registries | ASSUMPTIONS / RISK / UNKNOWNS reviewed, not empty shells? | pass / fail |
| Traceability | Scope ↔ ADR ↔ SPEC spot-check for touched contexts? | pass / fail / gap |
| Terminology | Doc 04 not called "the full plan" in artifacts? | pass / fail |
| Integrity (F1) | plan-master integrity on foundation? | pass / fail / waived |
| Probe coverage | If `{PLANS_ROOT}/foundation/PROBE_LEDGER.md` exists: `bash .ai/scripts/readiness-verify.sh` passes? Coverage % vs target; ★ gaps? | pass / gap / n/a |

### F3 - Foundation verify report (mandatory)

```markdown
## plan-verify foundation - <Project>

**Date:** <ISO> · **Mode:** foundation (read-only)

### Request interpretation
<when open language — insert interpretation block; otherwise: explicit foundation mode>

### Upstream
- **plan-foundation status:** embedded / cited above
- **plan-master integrity (foundation):** pass | pass with waivers | fail

### Check matrix
| Dimension | Result | Evidence / gap |
|-----------|--------|----------------|

### Readiness (report only — do not certify here)
- **foundation-complete:** yes | no
- **plan-master-ready:** yes | no
- **Probe coverage:** NN% (target 85%) · ledger honest: yes/fail | no ledger - if understanding is thin, run `@plan-foundation probe`

### Gaps
<ordered - severity High / Med / Low>

### Verdict
**pass** | **pass with gaps** | **fail** - <one sentence>

### Next step
- pass / pass with gaps (waived): `@plan-foundation certify plan-master-ready` or `@plan-master greenfield` if already certified
- fail: `@plan-repair repair - from foundation` or `@plan-repair foundation - <goal>`
```
---

## Master verify protocol (detailed)

<a id="master-verify-protocol"></a>

## Master verify protocol

Cross-check **master implementation plan** and **implementation-ready** prerequisites (report only — scoring follows plan-master status rules).

### Master verify — brownfield branch (BF)

When **BF0 = yes**:

1. If no `*-full-plan.md` but substitute exists (ROADMAP, milestones) → run **M3** against substitute; label **master artifact: substitute** with path.
2. If only NEXT/sprint doc → **master: partial**; alignment BF branch carries execution truth.
3. Do **not** emit blocked prerequisite solely for missing `Plan-master-ready:` — report **formal-plan-master-ready: no** and **Next:** `@plan-repair brownfield - master`.
4. **implementation-ready** must remain **no** unless an Approved `*-full-plan.md` exists (no brownfield waiver for broad execution).

### M0 - Prerequisite snapshot

If **plan-master-ready: no** in HANDOFF / foundation status:

- **brownfield: no** → verdict **fail** with **Run first:** `@plan-foundation certify plan-master-ready`.
- **brownfield: yes** → continue; report formal gate open; use [Master verify — brownfield branch](#master-verify--brownfield-branch-bf).

### M1 - Invoke upstream status (mandatory)

Follow `.ai/skills/plan-master/skill.md` § **Status protocol**. Record:

- Plan artifact path
- **Plan status:** Draft | Approved | …
- **implementation-ready:** yes | no (from plan-master — cite, do not re-score differently)
- Phase progress P0–P6 inside plan workflow

### M2 - Integrity on master plan (mandatory)

Follow `.ai/skills/plan-master/skill.md` § **integrity** when `*-full-plan.md` exists; if missing → **fail** with **Run first:** `@plan-master greenfield` or `@plan-repair master - create master plan from foundation`.

Record: **integrity:** pass | pass with waivers | fail

### M3 - Standard conformance (when plan exists)

Against `.ai/standards/20260519-MASTER_PLAN_STANDARD.md`:

| Dimension | Question | Result |
|-----------|----------|--------|
| Header metadata | Status, version, dates present? | pass / fail |
| §19 roadmap | Milestones M1… with task ids `M{N}-T{N}`? | pass / fail / gap |
| §20–§21 | Global acceptance + validation gates? | pass / fail / gap |
| Traceability | FR/NFR ids in tasks exist in plan body? Run `bash .ai/scripts/traceability-verify.sh` (every FR maps to a task M{N}-T{N})? | pass / fail / gap |
| Registries | Links to ASSUMPTIONS/RISK/UNKNOWNS — no duplicate forks? | pass / fail |
| Approved gate | Approved required for implementation-ready? | pass / fail / waived |
| Probe coverage | If `{PLANS_ROOT}/full/PROBE_LEDGER.md` exists: `bash .ai/scripts/readiness-verify.sh` passes? Coverage % vs target; ★ gaps? | pass / gap / n/a |

### M4 - Master verify report (mandatory)

```markdown
## plan-verify master - <Project>

**Date:** <ISO> · **Mode:** master (read-only)

### Request interpretation
<when open language — insert interpretation block; otherwise: explicit master mode>

### Upstream
- **plan-master status:** cited above
- **plan-master integrity:** pass | pass with waivers | fail

### Check matrix
| Dimension | Result | Evidence / gap |
|-----------|--------|----------------|

### Readiness (from plan-master — do not contradict)
- **implementation-ready:** yes | no
- **Probe coverage:** NN% (target 85%) · ledger honest: yes/fail | no ledger - if NFRs/FRs/risks are thin, run `@plan-master probe` → `@plan-master integrity`

### Gaps
<ordered>

### Verdict
**pass** | **pass with gaps** | **fail**

### Next step
- fail: `@plan-repair repair - from master` or `@plan-repair master - <goal>` or `@plan-master revise - <reason>`
- pass + not Approved: `@plan-master continue` or owner approval workflow
```
---

## Alignment verify protocol (detailed)

<a id="alignment-verify-protocol"></a>

## Alignment verify protocol

Detect drift between **tactical** (`{ITERATION_CARRIER}`) and **strategic** (`{MASTER_PLAN}`) layers per `20260518-tutorial-fix-existing-plans.md`.

### Alignment verify — brownfield branch (BF)

When **BF0 = yes**:

- If no `## Current iteration` but sprint doc / NEXT without block → **partial**; recommend `@plan-repair brownfield` or `@code-implementation plan - M{N}` after master substitute exists.
- If no `{MASTER_PLAN}` but ROADMAP / milestones → compare NEXT tasks to substitute; flag id mismatches as **Med** gaps (not automatic **fail**).
- Verdict **aligned-best-effort** allowed when NEXT is internally consistent with best available roadmap substitute.

### A0 - Existence gate

| Required | If missing (brownfield: no) | If missing (brownfield: yes) |
|----------|----------------------------|------------------------------|
| Valid `## Current iteration` in `{ITERATION_CARRIER}` | **fail** — `@code-implementation plan - M{N}` | **partial** — BF branch |
| `{MASTER_PLAN}` (latest `*-full-plan.md`) | **fail** — `@plan-master greenfield` or `@plan-repair master - …` | Use substitute per [BF branch](#alignment-verify--brownfield-branch-bf) |

### A1 - Alignment checks

| Check | Pass if |
|-------|---------|
| Milestone ref | Iteration header `M{N}` exists in plan §19 (or HANDOFF-documented section id) |
| Task ids | Iteration task ids match plan §19 exactly |
| FR/NFR | Iteration traces cite ids that exist in plan FR/NFR tables |
| Acceptance scope | Iteration acceptance is milestone-local, not whole-plan dump |
| Concept registry | Iteration registry matches SPEC §15 for touched features |
| Files column | Every task row has path or `TBD` + blocker |

### A2 - Alignment report

```markdown
## plan-verify alignment - M{N}: <name>

**Date:** <ISO> · **Plan:** <path> · **Iteration:** {ITERATION_CARRIER}

### Request interpretation
<when open language — insert interpretation block; otherwise: explicit alignment mode>

### Checks
| Check | Result | Evidence |

### Gaps
<ordered>

### Verdict
**pass** | **pass with gaps** | **fail**

### Next step
- Master wrong: `@plan-repair master - <reason>` or `@plan-master revise - <reason>`
- NEXT wrong only: `@code-implementation plan - M{N}` (after master is source of truth)
- Both: fix master first (tutorial §6 order)
```
---

## Coverage verify protocol (detailed)

<a id="coverage-verify-protocol"></a>

## Coverage verify protocol

**Triggers:** `@plan-verify coverage`, `@plan-verify registry`, or open language about **unmapped app surfaces** / **code-to-registry parity**.

**Objective:** Read-only inventory of **deployable application surfaces** (routes, pages, controllers, standalone utilities under `{APP}`) vs **registry artifacts** (`{FEATURE_SPEC_ROOT}/<slug>/*-SPEC.md` **Implementation map**, `{BOUNDARY_MAP}` / DIRECTORY_MAP rows). Ensures agents can locate code from `.work/` without ad-hoc tree walks.

**Not in scope:** Full behavioural SPEC review (use `@feature-spec review`); iteration task scope (use `@code-verify milestone`); framework self-check (use `bash scripts/framework-verify.sh` from Agent OS repo root).

**Legacy artifacts:** Project-specific `feature.yml` or domain-registry markdown files are **not** framework canon. Treat them as **substitutes** during inventory; migrate paths into SPEC **Implementation map** (FEATURE_STANDARD) when repairing.

### C0 - Prerequisites

| # | Read | When |
|---|------|------|
| 1 | `{AGENT_RULES_FILE}` — `REPLACE:APP_ROOT`, `REPLACE:FRONTEND_ROOT`, boundary placeholders | always |
| 2 | `standards/*DIRECTORY_MAP*` (or `{BOUNDARY_MAP}`) | always |
| 3 | `{FEATURE_SPEC_ROOT}/README.md` + each `*/…-SPEC.md` (Implementation map + Purpose) | always |
| 4 | Application tree under `{APP}` (2–3 levels; route entrypoints) | always |

If no application source exists → **skip** with verdict **pass** (nothing to map); suggest `@plan-verify foundation`.

### C1 - Surface inventory (mandatory)

Build a **surface list** — one row per independently routable or operable unit:

| Surface kind | Typical evidence (adapt per stack) |
|--------------|-----------------------------------|
| HTTP API routers / controllers | FastAPI `APIRouter`, Express routers, Nest modules |
| UI routes / pages | Next.js `pages/` or `app/`, React Router route files |
| BFF / API routes | `pages/api/`, server actions with distinct URLs |
| Workers / jobs | Celery tasks, queue consumers with dedicated modules |
| Standalone utilities | Scripts under `{APP}` invoked in production (not one-off `scripts/` dev tools unless documented in HANDOFF) |

**Exclude:** `tests/`, `migrations/`, generated code, vendor mirrors under `docs/integration/`, pure config.

Label each row **Confirmed** (file cite) | **Inference** (heuristic grouping).

### C2 - Registry mapping (mandatory)

For each surface, resolve **mapped slug** using this order:

1. SPEC **## Implementation map** (§14) path table (FEATURE_STANDARD) — **Confirmed**
2. DIRECTORY_MAP bounded-context / path row — **Confirmed** or **Inference**
3. SPEC Purpose / §6 APIs naming the surface — **Inference**
4. No match → **unmapped**

### C3 - Coverage matrix

| Surface | Mapped slug | Evidence | Status |
|---------|-------------|----------|--------|
| … | `<slug>` \| — | path + SPEC § | mapped \| unmapped \| waived |

**Waivers:** Only when HANDOFF or same-message user documents intentional orphan (e.g. deprecated module pending removal). Cite waiver id.

**Coverage %:** `mapped + waived` / total surfaces (round down; label **Estimate**).

### C4 - Coverage report (mandatory)

```markdown
## plan-verify coverage - <Project>

**Date:** <ISO> · **Mode:** coverage (read-only)
**Surfaces inventoried:** <N> · **Coverage:** <N>% (Estimate)

### Request interpretation
<when open language — insert block; else: explicit coverage mode>

### Unmapped surfaces
| Surface | Suggested slug | Notes |
|---------|----------------|-------|

### Waivers
<list or "none">

### Registry snapshot
| Slug | SPEC path | Has Implementation map? |
|------|-----------|-------------------------|

### Verdict
**pass** | **pass with gaps** | **fail**

### Next step
- gaps: `@plan-repair repair - from coverage` (or `@plan-repair brownfield` when framework slots also missing)
- pass: optional `bash scripts/framework-verify.sh` when validating Agent OS install
```

**Verdict rules:**

- **pass** — 100% mapped or only documented waivers; DIRECTORY_MAP references every bounded context with a SPEC.
- **pass with gaps** — ≤3 unmapped non-critical surfaces (shell fragments, dev-only) with repair plan obvious.
- **fail** — any unmapped production route/API/page cluster, or >10% unmapped without waivers.

### C5 - Optional persistence

When user asks to **record** the audit in the same message, write `{WORK_ROOT}/reports/YYYYMMDD-code-registry-audit.md` (summary + unmapped table only). Otherwise report in chat only — verify stays read-only.
