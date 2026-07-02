---
name: plan-foundation
description: >-
  Orchestrate foundation planning (P0–P6) and certify plan-master-ready. Use for
  foundation status, continue, greenfield, or certify. Does not author the master
  implementation plan or certify implementation-ready - that is plan-master.
---

# plan-foundation

**Workflow orchestrator** for project foundation - from idea through **plan-master-ready** certification. Stops there; **plan-master** owns the master roadmap and **implementation-ready**. Tool-agnostic (Cursor, Claude Code, opencode, Codex). Project-agnostic: paths use `.ai/` as the documentation root; adapt backend folder name (`apis/`, `src/`, `server/`) per ADR. **Product-intent capture** lives in **P0** of this skill: greenfield creates the **P0 initial scope** mini-plan at `{PLANS_ROOT}/foundation/YYYYMMDD-01-<slug>-initial-scope.md` (foundation doc 01). There is **no** separate `project-init` or `code-foundation` skill in this registry.

**Hard rule - `{PROMPTS_ROOT}/initial.md`:** User-owned scratch only. This skill **must not** read or create it unless the user **explicitly** names that path in the same invocation.

**Canonical path:** `.ai/skills/plan-foundation/skill.md` (this file). **Invocation examples:** `reference.md`.

---

## Role charter (anti-drift)

Guides foundation planning only — not implementation. **Charter, goals/boundaries, terminology, architecture directions, plan-master relationship, lifecycle, registries, traceability, gate model, integrity, hallucination prevention, fitness/UX/AI/cross-model rules:** [`reference.md` § Foundation concepts (detailed)](reference.md#foundation-concepts-detailed).

## Step 0 - Pick a mode (always first)

Detect from the user message. If ambiguous, ask once:

| Mode | User intent (examples) | Action |
|------|------------------------|--------|
| **status** | "foundation status", "plan-master-ready?", "foundation-complete?" | [Status protocol](#status-protocol) - read-only; **foundation-complete** + **plan-master-ready** only |
| **continue** | "continue foundation", "what's next", "resume planning" | [Continue protocol](#continue-protocol) - detect phase → next gate |
| **greenfield** | new project, empty repo, "start foundation" | [Greenfield protocol](#greenfield-protocol) - P0→P6 |
| **probe** | "probe the project", "ask me questions", "fill the gaps", "make sure you understand", "what else do you need to know?" | [Probe protocol](#probe-protocol) - adaptive coverage loop; read+write planning artifacts only |
| **certify** | "certify plan-master-ready", "verify foundation for plan-master" | Run [Plan-master readiness](#s4--plan-master-readiness); update HANDOFF if pass |

**Do not** run greenfield INTERACTIONs when the user asked for **status** only.

**Registry:** Full matrix - [`.ai/skills/SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md).

**Symmetric verify/repair:** `@plan-verify foundation` orchestrates this skill's **status** + `@plan-master integrity` on foundation artifacts; gaps → `@plan-repair foundation` or `@plan-foundation continue`.

---

## Prerequisite gate

| Mode | Gate |
|------|------|
| **greenfield** | [GF0](#gf0--bootstrap-artifacts) |
| **probe** | [GF0](#gf0--bootstrap-artifacts) (needs `{HANDOFF}` + doc 01 to record into); else suggest **greenfield** |
| **certify** | [CF0](#cf0--foundation-complete) |
| **continue** | Foundation started (≥1 foundation doc or HANDOFF notes P0); else suggest **greenfield** |
| **status** | - (read-only) |

### GF0 - Bootstrap artifacts

Before P0 INTERACTIONs:

1. If `{HANDOFF}` missing → **stop** with the [blocked-report shape](#blocked-report-shape):
   - **Required:** `{HANDOFF}` exists
   - **Detected:** `.work/context/HANDOFF.md` missing
   - **Run first:** `@project-bootstrap init` (or `@session-control` minimal HANDOFF only if user refuses bootstrap in the same message)
2. If `.cursorrules` missing at repo root → **stop** with the same shape:
   - **Required:** `.cursorrules` at repo root
   - **Detected:** missing
   - **Run first:** `@project-bootstrap init`
3. If `REPLACE:` tokens remain in `.cursorrules` → warn; foundation may proceed but record unfilled tokens in the greenfield report.

### CF0 - Foundation-complete

Before **certify**:

1. Evaluate [Foundation-complete (artifact check)](#s3b--foundation-complete-artifact-check).
2. If **foundation-complete: no** → **stop** with the [blocked-report shape](#blocked-report-shape):
   - **Required:** `foundation-complete: yes` (P0–P6 gates closed)
   - **Detected:** `foundation-complete: no` - failing phase/gate list from status
   - **Run first:** `@plan-foundation continue` (finish the failing phase, then re-invoke `certify`)

### Blocked-report shape

Per [SKILL_DEPENDENCIES.md § Blocked report shape](../SKILL_DEPENDENCIES.md#blocked-report-shape) - header: `## @plan-foundation <command> - blocked (prerequisite)`.

---

## Status protocol

### S1 - Resolve project identity

Read README → HANDOFF → `.cursorrules`; ask once if none. Details: [reference.md § Status protocol (detailed)](reference.md#status-protocol-detailed) (S1).

### S2 - Read session artifacts (if present)

Artifact read table (HANDOFF, NEXT, ADRs, registries, doc 04): [reference.md § Status protocol (detailed)](reference.md#status-protocol-detailed) (S2).

### S3 - Evaluate phases (evidence-based)

Phase table P0–P6, stage labels, evidence rules: [reference.md § Status protocol (detailed)](reference.md#status-protocol-detailed) (S3).

### S3b - Foundation-complete (artifact check)

**foundation-complete: yes** when P0–P6 gates pass. Report separately from plan-master-ready: [reference.md § Status protocol (detailed)](reference.md#status-protocol-detailed) (S3b).

### S4 - Plan-master readiness

Ten-criterion gate; HANDOFF record on pass. Full checklist: [reference.md § Status protocol (detailed)](reference.md#status-protocol-detailed) (S4).

### S5 - Out of scope: implementation-ready

Redirect to `@plan-master status`; do not score here: [reference.md § Status protocol (detailed)](reference.md#status-protocol-detailed) (S5).

### S6 - Status report format (mandatory)

Report template and rules: [reference.md § Status protocol (detailed)](reference.md#status-protocol-detailed) (S6).

---

## Continue protocol

1. Run **Status protocol** S1–S3 (short form - no full report unless user wants it).
2. Find the **first phase** not `done`.
3. If **partial**: complete that phase's **GATE** checklist (artifacts + [shared gate integrity](reference.md#shared-gate-integrity-every-gate)); produce missing artifacts.
4. Present the next **INTERACTION** only for unanswered questions in that phase (skip if answers exist in ADRs, foundation docs, or archived decision prompts).
5. Update registries (`ASSUMPTIONS`, `RISK_REGISTRY`, `UNKNOWNS`) when assumptions, risks, or unknowns change.
6. At GATE p3+ → apply [Architecture fitness review](reference.md#architecture-fitness-review); run `plan-master integrity` if contradictions found.
**Invoke as:** `@plan-master integrity` (Cursor) or "Follow .ai/skills/plan-master/skill.md - integrity mode" (opencode/Codex). Returns integrity score: pass | pass with waivers | fail.
7. Update `HANDOFF.md` and `NEXT.md` when a gate **passes** completion model (not merely when files are written).
8. At P6 done → evaluate [Plan-master readiness](#s4--plan-master-readiness) → offer `p6-done` confirm only if **plan-master-ready** (or list blockers).
9. After **plan-master-ready**: recommend `@plan-master greenfield` | `continue` - do not author master plan in plan-foundation.
10. After master plan exists → tell user to run `@plan-master status` for implementation-ready (not plan-foundation).
11. Do not write broad multi-milestone implementation without **plan-master** Approved master plan (or HANDOFF waiver).

---

Adaptive gap-driven interrogation before certification. Engine: **[`.ai/skills/probe-protocol.md`](../probe-protocol.md)**.

**Coverage profile, sub-modes, seven-step protocol, anti-patterns:** [`reference.md` § Probe protocol (detailed)](reference.md#probe-protocol-detailed).

---

## Certify protocol (plan-master-ready)

Use when the user asks to **certify**, **verify for plan-master**, or **plan-master-ready**.

0. Run [CF0 - Foundation-complete](#cf0--foundation-complete).
1. Run **Status protocol** S1–S3 (full evaluation).
2. Run `@plan-master integrity` on foundation artifacts (read-only if status-only; update HANDOFF on certify).
3. Evaluate [S4 - Plan-master readiness](#s4--plan-master-readiness) criterion by criterion with evidence.
4. Output certification report:

```markdown
## Plan-master-ready certification - <Project>

**Foundation-complete:** yes | no
**Plan-master-ready:** yes | no

### Criteria (S4)
| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 … 10 | | pass/fail | |

### If yes
- Record in HANDOFF: `Plan-master-ready: <date>`
Use when user asks to **certify** or **plan-master-ready**.

0. [CF0](#cf0--foundation-complete) → Status S1–S3 → `@plan-master integrity` → evaluate [S4](#s4---plan-master-readiness).
**Certification report template and steps:** [`reference.md` § Certify protocol (detailed)](reference.md#certify-protocol-detailed).

Do **not** create `*-full-plan.md` in certify mode.

**Binding:** Each phase has **Artifacts**, **GATE** checklist, and shared gate integrity. Greenfield INTERACTION ids (`p0-name`, `p1-integrations`, …) live in **`reference.md` § Greenfield walkthrough**.

**Phase headers, artifact paths, and GATE checklists (P0–P6):** [`reference.md` § Phase gates P0–P6 (detailed)](reference.md#phase-gates-p0-p6-detailed).

At P6 pass: evaluate [Plan-master readiness](#s4--plan-master-readiness); foundation orchestration certifies **plan-master-ready**; **plan-master** authors the [master plan artifact](reference.md#master-plan-artifact). **Not at P6:** implementation-ready (requires Approved master plan).


## Anti-patterns

- Running greenfield INTERACTIONs during a **status** request
- Editing archived decision prompts
- Writing broad implementation before plan-master master plan Approved
- SPEC after code; merged SPEC edits (use amendments)
- Collapsing inference into fact (assumption ledger / ASSUMPTIONS.md)
- TBD without ADR reference or UNKNOWNS entry
- AI attribution markers
- Skipping gates without documenting waiver in HANDOFF
- **File exists = phase done** (without shared integrity + registries)
- Ignoring `plan-master` when completing P3–P6 gates
- Duplicate registries inside plan-master artifact instead of linking `{PLANS_ROOT}/ASSUMPTIONS.md` etc.
- Marking **plan-master-ready** without `plan-master integrity` on foundation artifacts
- Evaluating **implementation-ready** inside plan-foundation status (use plan-master)
- Confusing **foundation-complete** with **plan-master-ready**
- Running `@plan-master greenfield` before **plan-master-ready: yes**
- Expanding `{PLANS_ROOT}/foundation/` into a substitute for `*-full-plan.md`
- Calling foundation doc 04 "the full plan" in reports (say **architecture foundation** or **foundation doc 04**)

0. [GF0](#gf0--bootstrap-artifacts) → `p0-name` → P0 doc 01 + registries → walk P0→P6 gates → sync assumption ledger → no broad code until plan-master **Approved**.

**Full step list:** [`reference.md` § Greenfield protocol (detailed)](reference.md#greenfield-protocol-detailed).

| **Plan-master-ready** | **yes** after `certify plan-master-ready` + integrity |
| **Master plan** | **Approved** under `{PLANS_ROOT}/full/` |
| **Implementation-ready** | Ask `@plan-master status` |
| **Next step** | `@session-control start` → `@code-implementation plan - M1` |
