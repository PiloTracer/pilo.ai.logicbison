---
name: plan-verify
description: >-
  Verification layer for planning artifacts: foundation (P0–P6), master plan,
  NEXT vs full-plan alignment, code-to-SPEC registry coverage, and brownfield
  framework alignment when plan-foundation or plan-master were never run formally.
  Orchestrates upstream status/integrity when present; otherwise assesses repo
  evidence against .ai slots. Use plan-verify foundation, master, alignment,
  coverage, brownfield, or open language.
---

# plan-verify

Verification layer for **planning documentation** — not application code. **Does not author** foundation docs or master plans; **does not** replace `plan-foundation` / `plan-master` mutating modes.

**Pairs with:** `plan-foundation` (foundation status + gate evidence), `plan-master` (master status + integrity), `plan-repair` (remediation after fail), `code-verify` (implementation layer — orthogonal), `.cursorrules` Completion Gate (evidence-first).

**Canonical path:** `.ai/skills/plan-verify/skill.md` · **Invocation examples:** `reference.md`

**Registry:** [`.ai/skills/SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md).

**Hard rules:**

- **Evidence-first** — cite file paths and quoted headings; never claim **pass** without running the checks in this skill or attaching upstream skill output from the same session.
- **Read-only** — no writes to `{HANDOFF}`, `{ITERATION_CARRIER}`, foundation docs, or `*-full-plan.md` unless the user explicitly asks to persist a verify result in HANDOFF.
- **Delegate, do not duplicate** — invoke upstream skills by **following** their `skill.md` protocols (same agent turn); do not reimplement certify, revise, or greenfield logic inline.
- **Layer discipline** — foundation verify must **not** score **implementation-ready** (redirect to `@plan-master status`). Master verify must **not** certify **plan-master-ready** (redirect to `@plan-foundation certify`).
- **Brownfield-first** — when [Brownfield detection](reference.md#brownfield-detection-bf0) is **yes**, use [Brownfield verify](reference.md#brownfield-verify-protocol) (or the BF branch inside the requested mode). Do **not** hard-stop solely because `@plan-foundation` / `@plan-master` were never run; assess **framework alignment** from repo evidence.
- Every mode ends with a **Completion checklist** — each item `pass` | `fail` | `skip` with evidence.
- **Operator handoff:** every response that ends a turn follows the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — terse output; approvals under `**Needs your approval:**` citing `path:L<n>`; questions numbered under `**Needs your answer:**`; exactly one `**Next step:**` command; one line when nothing is needed (Form A). Decisions and questions never mixed; empty sections omitted.

---

## Parse invocation

Normalize to **mode** + optional scope. Use ASCII hyphen **`-`** between tokens.

| User says | Mode | Action |
|-----------|------|--------|
| `@plan-verify` **foundation** | foundation | [Foundation verify](#foundation-verify-protocol) |
| `@plan-verify` **master** | master | [Master verify](#master-verify-protocol) |
| `@plan-verify` **alignment** | alignment | [Alignment verify](reference.md#alignment-verify-protocol) — NEXT vs `{MASTER_PLAN}` |
| `@plan-verify` **drift** | alignment | Alias for **alignment** |
| `@plan-verify` **status** | status | [Status protocol](#status-protocol) — read-only summary |
| `@plan-verify` **brownfield** | brownfield | [Brownfield verify](reference.md#brownfield-verify-protocol) — full framework alignment pass |
| `@plan-verify` **coverage** | coverage | [Coverage verify](#coverage-verify-protocol) — app surfaces vs SPECs / DIRECTORY_MAP |
| `@plan-verify` **registry** | coverage | Alias for **coverage** |
| `@plan-verify` **verify** | *(infer)* | See **Default** below |
| `plan-verify` **audit** **foundation** | foundation | Alias |
| `plan-verify` **check** **master** | master | Alias |
| Open language: "verify foundation planning", "audit master plan" | *(infer)* | Map keywords → mode; ask once if ambiguous |

**Default (bare `@plan-verify`):**

1. If `{ITERATION_CARRIER}` has valid `## Current iteration` → **alignment** (then offer **foundation** / **master** if user wants full stack).
2. Else if `{PLANS_ROOT}/full/*-full-plan.md` exists → **master**, then abbreviated **foundation** snapshot in report.
3. Else if `{PLANS_ROOT}/foundation/` has any doc → **foundation**.
4. Else if application source or product docs exist → **brownfield**.
5. Else → **foundation** (empty repo; bootstrap hints).

**Aliases:** `audit`, `check` → same mode inference as bare `@plan-verify`.

Open language → **brownfield** when user says: existing repo, legacy, never ran plan-foundation, adopt Agent OS, align to `.ai` framework, brownfield.

Open language → **coverage** when user says: unmapped surfaces, code-to-plan parity, feature catalog gap, 100% cataloged, map routers/pages to features, undocumented app surfaces.

### Open language interpretation (free requests)

**When:** The user message does **not** contain an explicit mode keyword (`foundation`, `master`, `alignment`, `brownfield`, `status`, `drift`) — or the keyword is embedded in a free-form sentence (e.g. "verify foundation planning", "audit master plan", "is our plan ready?").

Before running any protocol, emit a **Request interpretation** block that maps the open language to framework terms:

```markdown
### Request interpretation

**User said:** <raw text or paraphrase one line>

**Detected mode:** foundation | master | alignment | brownfield | status
**Mapped via:** <keyword match | default inference | user disambiguation>
**Framework components examined:**
| Component | Path | Why |
|-----------|------|-----|
| P0–P6 foundation docs | `{PLANS_ROOT}/foundation/*` | Mode: foundation |
| Plan-master status + integrity | `{PLANS_ROOT}/full/*-full-plan.md` | Mode: master |
| SPECs | `{FEATURE_SPEC_ROOT}/` | Per touched contexts |
| … | … | … |

**Assumption ledger:** <Confirmed | Inference | Unverified> for any ambiguous mapping
```

**Rules:**
- Emit the interpretation block **once** before the mode-specific protocol runs.
- When a keyword match is unambiguous (e.g. "audit master plan" → mode `master`), state **Confirmed**.
- When the mapping is probabilistic or the user question is vague, label **Inference** and ask once to confirm the detected mode before proceeding.
- Include the interpretation block in the report header (see report formats below).

When mode is explicit (e.g. `@plan-verify foundation`, `@plan-verify master`), skip the interpretation block and record: `**Request:** explicit mode — no interpretation needed`.

---

Run at start of **every** mode. Record **brownfield: yes | no** in report header.

**BF0 signals, Framework alignment map slot table, brownfield verify BF1–BF4, report template, verdict rules:** [`reference.md` § Brownfield detection and verify (detailed)](reference.md#brownfield-detection-and-verify-detailed).

---

## Shared prerequisites

| # | Read | When |
|---|------|------|
| 1 | `.cursorrules` placeholder map (`{PLANS_ROOT}`, `{HANDOFF}`, …) | all modes |
| 2 | `{HANDOFF}` | all modes |
| 3 | `{PLANS_ROOT}/ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md` | foundation, master |
| 4 | `.ai/standards/20260519-MASTER_PLAN_STANDARD.md` | master (section contract) |
| 5 | `.ai/docs/guides/workflows/20260518-tutorial-fix-existing-plans.md` | alignment |

---

## Foundation verify protocol

Cross-check **foundation layer** readiness: P0–P6 gates, registries, traceability, and semantic integrity on foundation artifacts.

### Foundation verify — brownfield branch (BF)

When **BF0 = yes**:

1. Run [BF1](reference.md#bf1-repo-discovery-mandatory) slot inventory for foundation rows only.
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

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md; any operator-required approval/question from **Gaps** / **Next step** must ALSO appear in the closing handoff block, enumerated with `path:line`.
```

---

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
- **brownfield: yes** → continue; report formal gate open; use [Master verify — brownfield branch](reference.md#master-verify-brownfield-branch-bf).

### M1 - Invoke upstream status (mandatory)

Follow `.ai/skills/plan-master/skill.md` § **Status protocol**. Record:

- Plan artifact path
- **Plan status:** Draft | Approved | …
- **implementation-ready:** yes | no (from plan-master — cite, do not re-score differently)
Cross-check foundation layer: P0–P6 gates, registries, traceability, semantic integrity.

**BF branch, F0–F3 steps, check matrix, report template:** [`reference.md` § Foundation verify protocol (detailed)](reference.md#foundation-verify-protocol).

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

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md; any operator-required approval/question from **Gaps** / **Next step** must ALSO appear in the closing handoff block, enumerated with `path:line`.
```

---

## Coverage verify protocol

**Triggers:** `@plan-verify coverage`, `@plan-verify registry`, or open language about **unmapped app surfaces** / **code-to-registry parity**.

**Objective:** Read-only inventory of **deployable application surfaces** (routes, pages, controllers, standalone utilities under `{APP}`) vs **registry artifacts** (`{FEATURE_SPEC_ROOT}/<slug>/*-SPEC.md` **Implementation map**, `{BOUNDARY_MAP}` / DIRECTORY_MAP rows). Ensures agents can locate code from `.work/` without ad-hoc tree walks.

**Not in scope:** Full behavioural SPEC review (use `@feature-spec review`); iteration task scope (use `@code-verify milestone`); framework self-check (use `bash scripts/framework-verify.sh` from Agent OS repo root).

**Legacy artifacts:** Project-specific `feature.yml` or domain-registry markdown files are **not** framework canon. Treat them as **substitutes** during inventory; migrate paths into SPEC **Implementation map** (FEATURE_STANDARD) when repairing.

### C0 - Prerequisites

| # | Read | When |
|---|------|------|
| 1 | `{AGENT_RULES_FILE}` — `REPLACE:APP_ROOT`, `REPLACE:FRONTEND_ROOT`, boundary placeholders | always |
| 2 | `.work/standards/*DIRECTORY_MAP*` (or `{BOUNDARY_MAP}`) | always |
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

**Exclude:** `tests/`, `migrations/`, generated code, vendor mirrors under `.work/docs/integration/`, pure config.

Label each row **Confirmed** (file cite) | **Inference** (heuristic grouping).

### C2 - Registry mapping (mandatory)

For each surface, resolve **mapped slug** using this order:

1. SPEC **## Implementation map** (§14) path table (FEATURE_STANDARD) — **Confirmed**
2. DIRECTORY_MAP bounded-context / path row — **Confirmed** or **Inference**
3. SPEC Purpose / §6 APIs naming the surface — **Inference**
4. No match → **unmapped**
Cross-check master plan and implementation-ready prerequisites (report only).

**BF branch, M0–M4 steps, conformance matrix, report template:** [`reference.md` § Master verify protocol (detailed)](reference.md#master-verify-protocol).


| Skill | Relationship |
|-------|----------------|
| `plan-foundation` | **Upstream** for foundation status; plan-verify **orchestrates**, does not replace |
| `plan-master` | **Upstream** for master status + integrity |
| `plan-repair` | **Downstream** on **fail** — `@plan-repair repair - from foundation` \| `from master` \| `from alignment` \| `from coverage` |
| `feature-spec` | **Downstream** for new slugs when coverage finds unmapped surfaces |
| `code-verify` | **Orthogonal** — code vs plan; run both before broad release |
| `code-repair` | Wrong layer for plan gaps — redirect to `plan-repair` |
| `code-implementation` | Regenerates iteration block after master/plan repair |

---

## Status protocol

Read-only summary of plan-verify readiness. Emit a compact table: foundation status (from `@plan-foundation status` when present), master status (`@plan-master status`), active iteration in `{ITERATION_CARRIER}`, and top gaps from `{PLANS_ROOT}/UNKNOWNS.md`. **No writes.** End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

---

## Completion checklist (all modes)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Mode detected | pass/fail | |
| 2 | Shared reads completed | pass/fail | paths |
| 3 | Upstream skill protocols run | pass/fail | |
| 4 | Check matrix filled | pass/fail | |
| 5 | Verdict matches evidence | pass/fail | |
| 6 | Next step names exact command | pass/fail | |
| 7 | No application code written | pass | |
| 8 | Layer labels not conflated | pass/fail | |
| 9 | Request interpretation emitted (when open language) | pass/skip | |
| 10 | Operator handoff close emitted (Form A or Form B) | pass/fail | |

---

## Anti-patterns

- Claiming **pass** without running integrity or citing upstream output
- Certifying **plan-master-ready** or **implementation-ready** inside plan-verify (use upstream skills)
- Using **alignment** when no iteration block exists — use **master** or **foundation** first
- Fixing docs during verify without user asking — use **plan-repair**
- Full foundation greenfield questionnaire during a **status** request
- Hard-stopping brownfield repos solely for missing formal certify (use BF branch + `@plan-repair brownfield`)
- Claiming **implementation-ready** or **plan-master-ready** from brownfield alignment alone
- Running open-language verify without emitting a **Request interpretation** block (see [Open language interpretation](#open-language-interpretation-free-requests))
- Claiming **100% cataloged** from framework slot alignment alone — run **coverage** when the question is code locate-ability
- Introducing parallel registries (`feature.yml`, per-repo domain-registry files) instead of SPEC **Implementation map** + DIRECTORY_MAP
- Burying operator actions/questions in prose instead of the closing Operator handoff block (Form A single line / Form B labeled sections)
Detect drift between `{ITERATION_CARRIER}` and `{MASTER_PLAN}`.

**BF branch, A0 existence gate, A1 checks, A2 report template:** [`reference.md` § Alignment verify protocol (detailed)](reference.md#alignment-verify-protocol-detailed).

Read-only inventory of deployable surfaces vs SPEC Implementation map + DIRECTORY_MAP.

**C0–C5 steps, surface inventory, mapping order, coverage matrix, report template, verdict rules:** [`reference.md` § Coverage verify protocol (detailed)](reference.md#coverage-verify-protocol).

