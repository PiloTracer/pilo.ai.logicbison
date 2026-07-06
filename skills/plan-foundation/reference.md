# plan-foundation - reference

Supplement to `skill.md`. **How to invoke**, **verify**, and **certify plan-master-ready**.

<a id="terminology-required--prevents-confusion-with-plan-master"></a>

**Anti-drift reminder:** `{PLANS_ROOT}/foundation/` (docs 01–04) = **foundation inputs**. `*-full-plan.md` = **master plan** (plan-master skill only). Never call doc 04 "the full plan" - say **architecture foundation** or **foundation doc 04**. Doc 01 heading: `Architecture directions (non-prescriptive - architecture foundation in doc 04)`. See [Terminology](#terminology-required--prevents-confusion-with-plan-master).

---

## Readiness states (do not confuse)

| State | Question | Who certifies | Unlocks |
|-------|----------|---------------|---------|
| **foundation-complete** | Do P0–P6 artifacts and gates pass? | plan-foundation **status** | Continue fixing foundation |
| **plan-master-ready** | Is foundation semantically mature enough for a master plan? | plan-foundation **certify** + `plan-master integrity` | `@plan-master greenfield` / `continue` |
| **implementation-ready** | Is the Approved master plan safe to execute broadly? | **plan-master** **status** only | Multi-milestone implementation |

---

## How to invoke (quick reference)

| Goal | Prompt (Cursor) | Mode |
|------|-----------------|------|
| Snapshot (foundation only) | `@plan-foundation` status | status |
| Ready for master plan? | `@plan-foundation` status - plan-master-ready? | status |
| Certify for plan-master | `@plan-foundation` certify plan-master-ready | certify |
| Resume incomplete gate | `@plan-foundation` continue | continue |
| New project from scratch | `@plan-foundation` greenfield - \<idea\> | greenfield |
| Ready to code? (broad) | `@plan-master` status - implementation-ready? | **plan-master** (not plan-foundation) |

**Explicit file path (any agent):**

```
Read .ai/skills/plan-foundation/skill.md - run status mode. Read-only.
```

```
Read .ai/skills/plan-foundation/skill.md - run certify mode. Update HANDOFF if plan-master-ready passes.
```

### Claude Code / opencode / Codex

```
Follow .ai/skills/plan-foundation/skill.md in status mode.
Report foundation-complete and plan-master-ready with evidence. Redirect implementation-ready questions to plan-master.
Do not create files unless certify mode and HANDOFF update requested.
```

```
Follow .ai/skills/plan-foundation/skill.md in certify mode.
Run plan-master integrity on foundation artifacts, then evaluate S4 criteria.
```

---

## Verification playbook

### Step 1 - Foundation status (always start here)

```
@plan-foundation status
```

**Agent must:**

1. Read `skill.md` Step 0 → **status**
2. Read S2 artifacts: HANDOFF, NEXT, foundation doc 04, registries, `*-full-plan.md` if present
3. Evaluate P0–P6 per gate completion model (not file-exists-only)
4. Report: **foundation-complete**, **plan-master-ready** only (if user asked implementation-ready → redirect to plan-master)

**Pass:** Report lists evidence paths per phase.  
**Fail:** Missing reads or only glob counts without integrity.

---

### Step 2 - Semantic integrity (before plan-master-ready)

When foundation-complete is **yes** but plan-master-ready is **not evaluated** or **no**:

```
@plan-master integrity
```

Or inline during certify:

```
@plan-foundation certify plan-master-ready
```

(plan-foundation orchestrates; plan-master supplies integrity rules.)

**Pass:** `plan-master integrity` → **pass** or **pass with waivers** in HANDOFF.  
**Fail:** Contradictions ADR ↔ SPEC ↔ foundation doc 04 → fix via `@plan-foundation continue`.

---

### Step 3 - Certify plan-master-ready

```
@plan-foundation certify plan-master-ready
```

**Agent must:**

1. Confirm all [S4 criteria](skill.md#s4-plan-master-readiness) (10 rows) with pass/fail + evidence
2. Require `plan-master integrity` result on **foundation** artifacts
3. On **yes**: write `Plan-master-ready: <date>` in HANDOFF §Repository state
4. Recommend next: `@plan-master greenfield` (no master plan yet) or `@plan-master continue` (draft exists)

**Do not** run `@plan-master greenfield` if certification is **no**.

---

<a id="master-plan-artifact"></a>

### Step 4 - Master implementation plan (plan-master skill)

After **plan-master-ready: yes**:

```
@plan-master greenfield
```

or

```
@plan-master continue
```

**Produces:** `{PLANS_ROOT}/full/YYYYMMDD-full-plan.md` ([master plan artifact](skill.md#master-plan-artifact))

**Pass:** Plan file exists with 25 mandatory sections; registries linked, not duplicated.  
**Not yet implementation-ready** until Status: **Approved**.

---

### Step 5 - Implementation-ready check (plan-master skill - not plan-foundation)

After master plan exists:

```
@plan-master status - implementation-ready?
```

**Agent must:** Evaluate master plan Approved + validation gates (plan-master skill). plan-foundation does **not** score this.

**Pass:** plan-master reports implementation-ready **yes** with evidence.

---

## Example - post-foundation sequence

| Check | Typical next step |
|-------|-------------------|
| foundation-complete | **no** → `@plan-foundation greenfield` or `continue` |
| plan-master-ready | **no** → `@plan-foundation certify plan-master-ready` |
| Master plan missing | `@plan-master greenfield` |
| implementation-ready | `@plan-master status` (authoritative) |

```
1. @plan-foundation status
2. @plan-foundation certify plan-master-ready
3. @plan-master greenfield
4. (owner reviews) → master plan Approved
5. @plan-master status
6. @session-control start → @code-implementation plan - M1
```

---

## Mode comparison

| Mode | Writes files | Runs plan-master integrity | Updates HANDOFF |
|------|--------------|--------------------------|-----------------|
| status | no | reports last result | no |
| certify | HANDOFF only if pass | **yes** (required) | yes on pass |
| continue | yes (artifacts) | at P3+ gates | yes on gate |
| greenfield | yes (P0→P6) | at P3+ gates | yes on gate |

---

## Integration with plan-master

| plan-foundation event | plan-master action |
|----------------------|------------------|
| GATE p3, p4, p5 | integrity subset |
| **certify** / GATE p6 | **integrity** on foundation (required) |
| plan-master-ready **yes** | **greenfield** or **continue** |
| Master plan Approved | **plan-master** **status** → implementation-ready |
| ADR ↔ SPEC contradiction | **integrity** |

---

## Planning registry templates

Create at **P0** (empty) or use seeded files in mature repos.

### ASSUMPTIONS.md

```markdown
# ASSUMPTIONS - planning registry
**Updated:** YYYY-MM-DD

| ID | Assumption | Label | Source | Notes |
|----|------------|-------|--------|-------|
| A1 | … | Confirmed \| Inference \| Unverified | path/ADR | |

## Rejected
| ID | Assumption | Reason |
```

### RISK_REGISTRY.md

```markdown
# RISK_REGISTRY - planning registry
| ID | Risk | Category | Likelihood | Impact | Mitigation | Status | Owner |
```

### UNKNOWNS.md

```markdown
# UNKNOWNS - planning registry
| ID | Question / blocker | Blocks | Owner | Status |
```

---

## P0 initial scope (product-intent capture)

**Owner skill:** `@plan-foundation` **greenfield** (Phase 0 - Capture). There is **no** `code-foundation` skill.

**Canonical path:** `{PLANS_ROOT}/foundation/YYYYMMDD-01-<project-slug>-initial-scope.md` (foundation doc 01).

**Not the seed:** `{PROMPTS_ROOT}/initial.md` - user-owned scratch; skills **must not** read or create unless the user explicitly names that path.

### Greenfield creates (minimum)

```markdown
# <Project Name> - Initial exploration and scope

## Audience and document purpose
…

## Assumption ledger

### Founder intent (verbatim - P0 capture)
<paste raw product idea from user>

### Confirmed facts (repository evidence)
…

## Architecture directions (non-prescriptive - architecture foundation in doc 04)
…
```

P1 expands doc 01; P1 also produces docs 02–04. Doc 01 is the **mini/preliminary plan** - not a prompt file.

---

## Glob patterns (artifact detection only)

Use for **foundation-complete** artifact presence - **not** for plan-master-ready (requires semantic checks).

| Phase | Glob | Min count |
|-------|------|-----------|
| P1 scope | `{PLANS_ROOT}/foundation/*-01-*.md` | 1 |
| P1 architecture | `{PLANS_ROOT}/foundation/*-04-*.md` | 1 |
| P2 ADRs | `{DECISIONS_ROOT}/20*.md` | ≥4 excluding README |
| P3 conventions | `.work/standards/*CONVENTIONS*.md` | 1 |
| P3 features | `{FEATURE_SPEC_ROOT}/*/20*-SPEC.md` | ≥1 |
| P4 stack | `REPLACE:TECH_STACK_DOC` | 1 |
| P5 compose | `docker-compose.yml` OR `*docker-compose-proposal*` | 1 |
| P6 ops | `README.md`, `HANDOFF.md`, `NEXT.md` | 3 |
| Registries | `ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md` | 3 |
| Master plan | `{PLANS_ROOT}/full/*-full-plan.md` | 0 until plan-master runs |

---

## Common blockers

| Blocker | Affects | Where |
|---------|---------|-------|
| Gate passed on file exists only | plan-master-ready | Re-run gate + shared integrity |
| No `plan-master integrity` run | plan-master-ready | `@plan-master integrity` |
| Master plan missing | implementation-ready | `@plan-master greenfield` |
| Master plan Draft | implementation-ready | Owner review → Approved |
| Open compliance / legal ADR | implementation-ready only (optional waiver for M1) | HANDOFF, UNKNOWNS |
| Docker not approved | foundation P5 | continue P5 |

---

## Wrong prompts

| Prompt | Problem | Use instead |
|--------|---------|-------------|
| `@plan-master greenfield` before certify | Master plan on weak foundation | `@plan-foundation certify` first |
| "@plan-foundation implementation-ready?" | Wrong skill | `@plan-foundation status` then `@plan-master status` |
| "foundation status" + write domain SPEC | Mixed modes | status, then continue |
| "start foundation" with full HANDOFF | Re-runs P0 | continue |
| Glob-only check | False pass | status + certify |

---

## Optional slash commands

| Command | Mode |
|---------|------|
| `/foundation status` | status |
| `/foundation certify` | certify |
| `/foundation continue` | continue |
| `/foundation start` | greenfield |

---

## Traceability quick check (P3+)

- [ ] Purpose → foundation scope (doc 01)
- [ ] ADRs referenced in SPEC
- [ ] R1… in test plan
- [ ] Row in plan-master trace matrix (when master plan exists)

---

## Gate pass vs semantic pass

| Wrong | Right |
|-------|-------|
| Files on disk → plan-master-ready | certify + S4 + integrity |
| HANDOFF complete, empty UNKNOWNS | Deferred ADRs in UNKNOWNS |
| P6 done → implementation-ready | P6 → plan-master-ready → plan-master → Approved → implementation-ready |

---

## Foundation coverage map

The **coverage profile** consumed by `@plan-foundation probe` (engine: [`.ai/skills/probe-protocol.md`](../probe-protocol.md)). Each dimension lists "what good looks like" and the [S4](skill.md#s4-plan-master-readiness) criteria it unblocks. Gate-blocking dimensions (weight 2 in the Coverage Score) are marked **★**.

| Dim | Topic | What good looks like | Primary S4 link | Records into |
|-----|-------|----------------------|-----------------|--------------|
| **D1 ★** | Product intent & success | Founder intent verbatim + measurable success criteria | S4-7 (traceability from goal) | doc 01 §Founder intent |
| D2 | Audience / personas | Named personas or user types; primary journeys | S4-9 (UX/UI direction) | doc 01 §Audience; personas-v1 |
| **D3 ★** | Scope in / out | Explicit in-scope and out-of-scope for v1 | S4-1 (foundation-complete) | doc 01 §Scope |
| D4 | Functional capabilities | Core capabilities enumerated; map to bounded contexts | S4-3 (high-risk SPECs) | doc 01; SPEC drafts |
| **D5 ★** | NFRs | Quantified perf/availability/security/privacy/i18n/a11y/cost targets | S4-8 (architecture fitness) | doc 04; observability/threat-model |
| D6 | Integrations & ext deps | External APIs/files identified + mirrored (MANIFEST) | S4-8 (fitness) | doc 02; MANIFEST |
| D7 | Data model & sensitivity | Key entities + PII/data-classification | S4-8 (security/fitness) | data-classification standard |
| D8 | Constraints | Budget, timeline, team size, ops model, hosting limits | S4-2 (core ADRs) | ASSUMPTIONS; doc 01 |
| **D9 ★** | Deploy / hosting / tenancy | Hosting, tenancy model, deploy/rollback path decided | S4-2, S4-4 (ADRs + map) | ADRs; doc 04 |
| **D10 ★** | Risks & assumptions | Top risks have mitigation+owner; assumptions labeled | S4-5 (registries) | RISK_REGISTRY; ASSUMPTIONS |

**Target:** Coverage ≥ 85% with no ★ dimension below **partial**. **Ledger:** `{PLANS_ROOT}/foundation/PROBE_LEDGER.md` (template: `templates/work/plans/foundation/PROBE_LEDGER.md.template`).

**Invocation (Cursor):** `@plan-foundation probe` · `@plan-foundation probe - until ready` · `@plan-foundation probe - status`
**Any agent:** `Read .ai/skills/plan-foundation/skill.md - run probe mode. Use the Foundation coverage map and .ai/skills/probe-protocol.md engine. Record answers into doc 01 + registries; update PROBE_LEDGER.md.`

---

## Greenfield walkthrough - INTERACTION and IF templates

Used by `@plan-foundation greenfield`. Skill body holds **Phase headers, Artifacts, and GATE checklists** (binding); this section holds the **questionnaires** (scaffolding the agent reads when running greenfield).

### Interaction block format

```markdown
## INTERACTION: <id>
**Q:** <question>
**Type:** single_select | multi_select | free_text | confirm
**Options:** (omit for free_text/confirm)
- `value` | Label | Why this matters
**Default:** <value>  (optional)
**Skip if:** <file or ADR exists>  (optional)
```

Branch with `## IF: <id> = <value>`.

### Owner decision questionnaires (any phase)

When a product choice blocks SPECs (UX mode, vertical, compliance wording):

1. Create `{PROMPTS_ROOT}/decision_<NNN>_<slug>.md` with questions + space for owner answers.
2. Create `{DECISIONS_ROOT}/YYYYMMDD-<NNN>-<slug>-proposed.md`.
3. After owner fills the prompt → **Decided** ADR + `{FEATURE_SPEC_ROOT}/<slug>/YYYYMMDD-SPEC-amendment-NN.md`.
4. **Archive the prompt** - add "do not edit"; never delete owner answers.

### Phase 0 - Capture (interactions)

**Mandatory order (binding):** `p0-name` → `p0-intent` → `p0-probe` → **then** Phase 1. Do **not** skip ahead to `p1-integrations` or any stack/hosting INTERACTION until `p0-probe` exits.

#### INTERACTION: p0-name

**Q:** What is this project called? (Used in README, HANDOFF, and .cursorrules.)
**Type:** free_text
**Skip if:** README or HANDOFF already names the project and user did not ask to rename

#### INTERACTION: p0-intent

**Q:** Describe the project in as much detail as you can — the problem you are solving, who it is for, core workflows, what success looks like, constraints you already know, and anything else that matters. Paste a full initial prompt if you have one; more detail now means fewer wrong assumptions later.
**Type:** free_text
**Depends on:** `p0-name` answered (or skipped)
**Skip if:** doc 01 §Founder intent already has substantive content (≥2 sentences or a pasted prompt block)
**On answer:** Create or update doc 01; paste the answer **verbatim** under `### Founder intent (verbatim - P0 capture)` in the assumption ledger. Do **not** summarize or rewrite yet.

#### INTERACTION: p0-probe

**Type:** probe_loop (engine: [`.ai/skills/probe-protocol.md`](../probe-protocol.md))
**Depends on:** `p0-intent` answered (or skipped with substantive founder intent already in doc 01)
**Coverage subset (product only — no tech yet):** D1 (product intent & success), D2 (audience/personas), D3 (scope in/out), D4 (functional capabilities), D8 (constraints: budget, timeline, team, ops)
**Exclude until Phase 1:** D5 (quantified NFRs), D6 (integrations), D7 (data model), D9 (deploy/hosting/tenancy), D10 (risks — capture obvious ones inline, formal registry sync at GATE p0)
**Target:** D1 and D3 at least **partial**; D2 and D4 addressed (not **unknown**); user had opportunity to defer remaining gaps
**Batch size:** ≤5 targeted questions per iteration (probe-protocol default)
**Record into:** doc 01 (audience, scope, capabilities sections), `ASSUMPTIONS.md`, `UNKNOWNS.md`, `RISK_REGISTRY.md`, `{PLANS_ROOT}/foundation/PROBE_LEDGER.md` (create registry files from templates on first write if missing — see greenfield step 3)
**Exit when:** product dimensions meet target **or** user says stop/defer/enough **or** three iterations with no new high-priority gaps
**Hard rule:** Do **not** present `p1-integrations`, `p1-adjacent`, `p2-*`, or any stack/hosting INTERACTION until this step exits. If the user asks for tech choices early, acknowledge and redirect: product understanding first.

### Phase 1 - Exploration (interactions)

**Prerequisite:** `p0-probe` exited. Phase 1 starts with **inferred** integrations, not a blank checklist.

#### INTERACTION: p1-integrations

**Pre-step (agent — before asking):** From doc 01 + probe answers, infer likely external dependencies (REST APIs, gov/regulatory systems, payments, file exchange, auth/IdP, webhooks, etc.). For each inference: one-line rationale tied to a user statement or labeled **assumption** if inferred.
**Q:** Based on what you described, these external integrations look relevant for v1:

`<agent numbered list: integration | rationale | assumed vs stated>`

Which apply? What is missing? What is explicitly **out of scope** for v1?
**Type:** multi_select + free_text follow-up
**Options:** (generate from pre-step — include `none` only if the agent found zero plausible deps)
- `rest-api` | REST API | External HTTPS service
- `gov-api` | Government / regulatory API | Tax, customs, e-invoicing
- `payment` | Payment gateway | Stripe, acquirer, etc.
- `file-exchange` | File exchange | XSD, EDI, CSV import/export
- `auth-idp` | Auth / identity provider | SSO, OAuth, enterprise IdP
- `webhooks` | Inbound/outbound webhooks | Event-driven partners
- `none` | None confirmed | No external deps in v1 (only after agent pre-step found none)
**Follow-up (mandatory when any integration selected):** ≤5 grill questions on that integration — vendor/system name, sandbox availability, auth model, data sensitivity, failure modes, v1 must-have vs defer.
**Depends on:** `p0-probe` exited

#### IF: p1-integrations includes gov-api or file-exchange

Mirror vendor artifacts under `.work/docs/integration/<vendor>-<version>/` + `MANIFEST.txt` (URL, path, SHA-256, date).

#### INTERACTION: p1-adjacent

**Q:** Adjacent modules users will eventually need?
**Type:** multi_select
**Options:**
- `inventory` | Inventory | Stock, warehouses
- `accounting` | Accounting | GL, journal entries
- `crm` | CRM | Customer management
- `pos` | POS | Hardware, quick-sale
- `reporting` | BI/Reporting | Dashboards, exports
- `ecommerce` | E-commerce | Online store sync
- `none` | None | v1 is self-contained

### Phase 2 - ADRs (interactions)

#### INTERACTION: p2-backend

**Q:** Backend stack?
**Type:** single_select
**Options:**
- `python-fastapi` | Python + FastAPI
- `ts-node` | TypeScript + Node.js
- `go` | Go
- `rust` | Rust
- `csharp` | C# + .NET
**Default:** python-fastapi

#### INTERACTION: p2-frontend

**Q:** Frontend?
**Type:** single_select
**Options:**
- `nextjs` | Next.js + React
- `react-vite` | React + Vite
- `vue` | Vue/Nuxt
- `svelte` | SvelteKit
- `none` | API/CLI only
**Default:** nextjs

#### INTERACTION: p2-hosting

**Q:** Hosting?
**Type:** single_select
**Options:**
- `aws` | AWS
- `gcp` | Google Cloud
- `fly` | Fly.io
- `railway` | Railway
- `vps` | VPS / bare metal
**Default:** aws

#### INTERACTION: p2-tenancy

**Q:** Multi-tenant?
**Type:** single_select
**Options:**
- `schema-per-tenant` | Schema-per-tenant
- `row-level` | Row-level (RLS)
- `single-tenant` | Single-tenant deployments
**Default:** schema-per-tenant for SaaS; single-tenant for on-prem products

#### INTERACTION: p2-locales

**Q:** UI/document languages?
**Type:** multi_select
**Options:** `en`, `es`, `zh`, `ru`, `pt`
**Default:** en

### Phase 5 - Infrastructure (interactions)

#### INTERACTION: p5-local-dev

**Q:** Local dev setup?
**Type:** single_select
**Options:** `docker-compose` | `bare` | `devcontainer`
**Default:** docker-compose

#### INTERACTION: p5-sandbox

**Q:** Sandbox runbook for external API onboarding?
**Type:** single_select
**Options:** `yes` | `no`
**Default:** yes if p1-integrations != none

#### INTERACTION: p5-approve-compose

**Q:** Review the docker compose proposal. Approve and create `docker-compose.yml`, `Dockerfile.*`, `.env.example`?
**Type:** confirm
**Depends on:** p5-local-dev = docker-compose
**Affects:** docker-compose.yml, Dockerfile.api, Dockerfile.dashboard, .env.example, HANDOFF.md, NEXT.md

#### IF: p5-approve-compose = yes

Create the files per the proposal. Update HANDOFF and NEXT to reflect approval.

### Phase 6 - Operations (interactions)

#### INTERACTION: p6-done

**Q:** Foundation P0–P6 is complete and **plan-master-ready** is certified. Proceed to **plan-master** for the master implementation plan (`{PLANS_ROOT}/full/YYYYMMDD-full-plan.md`)?
**Type:** confirm
**Skip if:** plan-master-ready is **no** - list blockers; use **continue** instead

**On confirm:**

1. Set HANDOFF: foundation gate snapshot complete; **Plan-master-ready: \<date\>**.
2. Invoke: `@plan-master greenfield` (or `continue` if `*-full-plan.md` exists).
3. After master plan exists: user runs `@plan-master status` for **implementation-ready** (not plan-foundation).
4. M1 skeleton (NEXT.md) may start when **plan-master-ready: yes** even if master plan is Draft - document waiver if skipping plan-master.
---

## Phase gates P0–P6 (detailed)

<a id="phase-gates-p0-p6"></a>

## Phase 0 - Capture

**Artifacts:**

```
{PLANS_ROOT}/foundation/YYYYMMDD-01-<slug>-initial-scope.md   - P0 mini-plan (greenfield creates; plan-foundation owns)
.cursorrules                     - identity, core principles, protected files
{PLANS_ROOT}/ASSUMPTIONS.md      - created at P0
{PLANS_ROOT}/RISK_REGISTRY.md
{PLANS_ROOT}/UNKNOWNS.md
```

**Greenfield questions:** `p0-name`, `p0-intent`, `p0-probe` — see `reference.md` § Phase 0. **Do not** enter Phase 1 until all three complete (or skip where allowed).

### GATE: p0

- [ ] **P0 initial scope** mini-plan at `{PLANS_ROOT}/foundation/*-01-*-initial-scope.md` (founder intent captured verbatim from `p0-intent`)
- [ ] **Product probe** complete: `p0-probe` exited; D1/D3 at least partial; D2/D4 addressed; `PROBE_LEDGER.md` started
- [ ] `.cursorrules` created with project name and evidence-first / no-PII principles
- [ ] Planning registries created (`ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md`)

**Includes:** [Shared gate integrity](#shared-gate-integrity-every-gate)

---

## Phase 1 - Exploration

**Artifacts:**

```
{PLANS_ROOT}/foundation/YYYYMMDD-01-*-scope.md
{PLANS_ROOT}/foundation/YYYYMMDD-02-*-integration.md     ← skip if p1-integrations = none
{PLANS_ROOT}/foundation/YYYYMMDD-03-*-adjacency.md        ← skip if none adjacent
{PLANS_ROOT}/foundation/YYYYMMDD-04-foundation-arch.md
.work/docs/integration/MANIFEST.txt                           ← skip if no integration mirror
```

Doc 01 sections: Audience, Assumption ledger, Scope, Risks; heading **Architecture directions (non-prescriptive - architecture foundation in doc 04)** per [Terminology](#terminology-required--prevents-confusion-with-plan-master). Doc 04: Bounded contexts, decisions register §13, foundation-ready gate §14 - title may say "plan" but role is **architecture foundation**, not `*-full-plan.md`.

**Greenfield questions:** `p1-integrations`, `p1-adjacent` and IF branch for gov-api / file-exchange - see `reference.md` § Phase 1.

### GATE: p1

- [ ] Scope doc (01) exists; uses **architecture foundation in doc 04** wording (not "full plan in doc 04")
- [ ] Architecture foundation doc (04) exists with bounded contexts + dependency direction
- [ ] 01↔02↔03↔04 cross-linked
- [ ] Integration mirror + manifest (if applicable)
- [ ] Open questions explicit in `UNKNOWNS.md` (synced from doc 01 assumption ledger)
- [ ] Initial risks in `RISK_REGISTRY.md` (scope, integration, compliance)

**Includes:** [Shared gate integrity](#shared-gate-integrity-every-gate)

---

## Phase 2 - ADRs

**Artifacts:**

```
{DECISIONS_ROOT}/README.md
{DECISIONS_ROOT}/YYYYMMDD-001-backend-stack.md
{DECISIONS_ROOT}/YYYYMMDD-002-*.md …
```

ADR: Context → Decision → Consequences → Alternatives → References. Status: `Proposed | Decided | Deferred | Superseded`.

**Greenfield questions:** `p2-backend`, `p2-frontend`, `p2-hosting`, `p2-tenancy`, `p2-locales` - see `reference.md` § Phase 2.

### GATE: p2

- [ ] ADR index current
- [ ] Stack, hosting, tenancy ADRs **Decided**
- [ ] Deferred ADRs document what they block (entries in `UNKNOWNS.md`)
- [ ] Major ADRs trace to business goals / foundation scope

**Includes:** [Shared gate integrity](#shared-gate-integrity-every-gate) · Recommend [Cross-model verification](#cross-model-verification) for Decided ADRs

---

## Phase 3 - Specifications

```
.work/standards/YYYYMMDD-CONVENTIONS.md
.work/standards/YYYYMMDD-FEATURE_STANDARD.md
.work/standards/YYYYMMDD-DIRECTORY_MAP.md
{FEATURE_SPEC_ROOT}/<bounded-context>/YYYYMMDD-SPEC.md
{FEATURE_SPEC_ROOT}/<slug>/YYYYMMDD-SPEC-amendment-NN.md
```

SPEC sections: Purpose · In/Out scope · Domain language · Rules (R1…) · Data model · APIs · Invariants · Errors · Observability · Security · i18n · Test plan · Open questions · Residual verification.

**Rule:** Do not edit merged SPECs; use amendment siblings.

---

### GATE: p3

- [ ] Conventions + feature standard + directory map on disk
- [ ] ≥1 feature SPEC with numbered behavioural rules
- [ ] SPECs for highest-risk bounded context(s) identified in doc 04
- [ ] Traceability: each SPEC lists ADRs + testable R1… rules
- [ ] [Architecture fitness review](#architecture-fitness-review) recorded

**Includes:** [Shared gate integrity](#shared-gate-integrity-every-gate) · Run `plan-master integrity` subset if high-risk / compliance SPEC present

---

## Phase 4 - Cross-cutting

```
REPLACE:TECH_STACK_DOC
.work/standards/YYYYMMDD-threat-model.md
.work/standards/YYYYMMDD-data-classification.md
.work/standards/YYYYMMDD-observability-spec.md
.work/standards/YYYYMMDD-api-style-guide.md
{PLANS_ROOT}/YYYYMMDD-personas-v1.md               ← if UI (p2-frontend != none)
```

Optional: `{PLANS_ROOT}/operations/YYYYMMDD-cpa-shortlist.md`, `YYYYMMDD-regulatory-changelog-watch.md` when gov-api or heavy compliance.

---

### GATE: p4

- [ ] Tech stack pins versions; TODOs trace to ADRs or `UNKNOWNS.md`
- [ ] Threat model + data classification exist
- [ ] Observability names metrics per context
- [ ] API style guide sufficient to implement HTTP layer
- [ ] [UX/UI validation](#uxui-validation) (if UI in scope)
- [ ] Security/scalability risks updated in `RISK_REGISTRY.md`

**Includes:** [Shared gate integrity](#shared-gate-integrity-every-gate) · [Architecture fitness review](#architecture-fitness-review)

---

## Phase 5 - Infrastructure

**Artifacts:**

```
{PLANS_ROOT}/operations/YYYYMMDD-docker-compose-proposal.md
{PLANS_ROOT}/operations/YYYYMMDD-sandbox-onboarding.md
```

**Rule:** `docker-compose.yml`, `Dockerfile.*`, `.env.example` - create only after explicit owner approval.

**Greenfield questions:** `p5-local-dev`, `p5-sandbox`, `p5-approve-compose` and IF branch - see `reference.md` § Phase 5.

### GATE: p5

- [ ] Docker approved + files created, OR bare-metal documented, OR approval pending in HANDOFF
- [ ] Sandbox runbook if external integration
- [ ] Ports chosen, .env.example committed
- [ ] Operational/deployment risks in `RISK_REGISTRY.md`
- [ ] Deploy/rollback feasibility noted (HANDOFF or proposal)

**Includes:** [Shared gate integrity](#shared-gate-integrity-every-gate) · [Architecture fitness review](#architecture-fitness-review) (deployment realism)

---

## Phase 6 - Operations

```
README.md
{HANDOFF}
{ITERATION_CARRIER}
.gitignore
.claudeignore                    ← recommended for large vendor mirrors
```

---

### GATE: p6 (FINAL)

- [ ] README start-here table
- [ ] HANDOFF fresh-start checklist + gate snapshot
- [ ] NEXT.md single recommended next action
- [ ] Cross-links valid; no secrets/PII/attribution markers
- [ ] Registries current (`ASSUMPTIONS`, `RISK_REGISTRY`, `UNKNOWNS`)
- [ ] [Plan-master readiness](#s4--plan-master-readiness) evaluated - record **plan-master-ready: yes | no** in HANDOFF

**Includes:** [Shared gate integrity](#shared-gate-integrity-every-gate)

**Not at P6:** implementation-ready (requires Approved master plan - evaluate after plan-master).

**Greenfield question:** `p6-done` (confirm) - see `reference.md` § Phase 6.

Foundation orchestration certifies **plan-master-ready**; **plan-master** authors the [master plan artifact](#master-plan-artifact).

---
---

## Status protocol (detailed)

<a id="status-protocol-detailed"></a>

### S1 - Resolve project identity

1. Read `README.md` (first `#` heading or project name in intro).
2. Else read `{HANDOFF}` (title or "Repository state").
3. Else read `.cursorrules` (Identity section).
4. If none exist: ask once - **"What is this project called?"** - then use that label in the report only (do not invent files).

### S2 - Read session artifacts (if present)

| File | Purpose |
|------|---------|
| `{HANDOFF}` | Session boundary, explicit unknowns, gate snapshot |
| `{ITERATION_CARRIER}` | Backlog, recommended next, owner blockers |
| `{DECISIONS_ROOT}/README.md` | ADR index |
| `REPLACE:TECH_STACK_DOC` | Stack pins + TODOs |
| `{PLANS_ROOT}/foundation/*-04-*.md` | §13 decisions + §14 foundation gate |
| `{PLANS_ROOT}/ASSUMPTIONS.md` | Assumption governance |
| `{PLANS_ROOT}/RISK_REGISTRY.md` | Risk lifecycle |
| `{PLANS_ROOT}/UNKNOWNS.md` | Open questions and blockers |
| `{PLANS_ROOT}/full/*-full-plan.md` | If present: note path only; **do not** evaluate implementation-ready in foundation status |

### S3 - Evaluate phases (evidence-based)

For each phase, set: **done** | **partial** | **not started**. Use the [Gate completion model](#gate-completion-model) and phase GATE sections. Cite paths as evidence. Mark inferences as **Unverified**. A phase is **not** `done` if [shared gate integrity](#shared-gate-integrity-every-gate) failed.

| Phase | Name | Typical evidence |
|-------|------|------------------|
| P0 | Capture | **P0 initial scope** mini-plan (`{PLANS_ROOT}/foundation/*-01-*-initial-scope.md`), `.cursorrules`, planning registries |
| P1 | Foundation discovery | `{PLANS_ROOT}/foundation/` docs 01–04; optional `02` + `MANIFEST.txt` |
| P2 | ADRs | `{DECISIONS_ROOT}/README.md`, `YYYYMMDD-001` … (core four decided) |
| P3 | Specifications | `CONVENTIONS`, `FEATURE_STANDARD`, `DIRECTORY_MAP`, `{FEATURE_SPEC_ROOT}/*/SPEC` |
| P4 | Cross-cutting | `REPLACE:TECH_STACK_DOC`, threat-model, data-classification, observability, api-style-guide |
| P5 | Infrastructure | docker-compose **proposal** or committed compose; sandbox runbook if external API |
| P6 | Operations | `README.md`, `HANDOFF.md`, `NEXT.md`, `.gitignore` |

**Stage label** (summary for humans):

| Stage | Condition |
|-------|-----------|
| **Not started** | P0 not done |
| **Exploring** | P0–P1 done; P2 incomplete |
| **Deciding** | P2 partial; stack/tenancy ADRs open |
| **Specifying** | P2 core done; P3–P4 in progress |
| **Planning complete** | P0–P6 gates pass; **no** `apis/` / app source |
| **Plan-master ready** | [Plan-master readiness](#s4--plan-master-readiness) **yes** |
| **Implementation started** | Application source tree exists |

### S3b - Foundation-complete (artifact check)

**foundation-complete: yes** when P0–P6 gates pass per [Gate completion model](#gate-completion-model) (file + integrity per phase).

This is **necessary but not sufficient** for plan-master or implementation. Always report **foundation-complete** separately from **plan-master-ready**.

### S4 - Plan-master readiness

Answer **plan-master-ready: yes** only when **all** are true:

1. **foundation-complete: yes** (P0–P6 gates done per gate completion model).
2. Core ADRs **Decided** (stack, hosting, tenancy - project defines "core"; deferred ADRs documented in `UNKNOWNS.md`).
3. Highest-risk bounded context(s) have SPECs with numbered rules (project defines - e.g. payments, compliance).
4. Directory map exists and aligns with foundation doc 04 bounded contexts.
5. Registries populated and reviewed: `ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md`.
6. No **unresolved architectural contradictions** (ADR ↔ foundation doc 04 ↔ SPECs), or waivers in HANDOFF.
7. **Traceability spot-check** passes for requirements touched in foundation (see [Traceability requirement](#traceability-requirement)).
8. **[Architecture fitness review](#architecture-fitness-review)** passes for P3–P6 scope (record in HANDOFF or RISK_REGISTRY).
9. **UX/UI direction** sufficient when UI in scope ([UX/UI validation](#uxui-validation)).
10. **`plan-master integrity`** on **foundation artifacts** returns **pass** or **pass with waivers** documented in HANDOFF (run via plan-master skill; plan-foundation records result).

If any fail → **plan-master-ready: no** + list blockers + recommend **continue** foundation (not plan-master greenfield yet).

**On pass:** Record in HANDOFF §Repository state: `Plan-master-ready: <date>`. Recommend `@plan-master greenfield` or `continue`.

**Anti-pattern:** Running `@plan-master greenfield` when plan-master-ready is **no**.

### S5 - Out of scope: implementation-ready

**Do not** evaluate or certify **implementation-ready** in plan-foundation modes (status, certify, continue, greenfield).

If the user asks "implementation-ready?" or "ready to code?":

1. If **plan-master-ready: no** → answer foundation blockers first.
2. If no `*-full-plan.md` → recommend `@plan-master greenfield` after certify.
3. If master plan exists → redirect: `@plan-master status` (implementation-ready is defined in plan-master skill).

**M1 skeleton** (tactical): may proceed when **plan-master-ready: yes** per NEXT.md and HANDOFF waivers - not the same as implementation-ready.

### S6 - Status report format (mandatory)

```markdown
## Foundation status - <Project Name>

**As of:** <date> · **Mode:** status (read-only)

### Summary
- **Stage:** <stage label>
- **Foundation-complete:** yes | no
- **Plan-master-ready:** yes | no | not evaluated
- **Recommended next:** <continue foundation | certify | @plan-master greenfield>

### Implementation-ready (redirect only - do not score here)
- Master plan: <missing | path - use @plan-master status for Approved/implementation-ready>

### Phase progress
| Phase | Status | Evidence |
|-------|--------|----------|
| P0 … P6 | done/partial/not started | paths |

### Open ADRs / decisions
- <list from decisions/README or HANDOFF>

### Owner blockers
- <from NEXT.md / HANDOFF>

### Risks / unverified
- <from RISK_REGISTRY.md / UNKNOWNS.md>

### Registry snapshot
- Assumptions: <count unresolved>
- Risks: <count open>
- Unknowns: <count blocking>

### Integrity (plan-master)
- Last run: <date or not run> · Result: pass | fail | waived
- **Invoke:** `@plan-master integrity` (Cursor) or "Follow .ai/skills/plan-master/skill.md - integrity mode" (opencode/Codex)
```

**Rules:** Do not modify files in status mode unless the user asks. Do not edit prompts marked **archived** or "do not edit".
---

## Probe protocol (detailed)

<a id="probe-protocol-detailed"></a>

## Probe protocol

Adaptive, gap-driven interrogation that **guarantees foundation understanding** before certification. Engine: **[`.ai/skills/probe-protocol.md`](../probe-protocol.md)** (the loop, scoring, ledger, and ease-of-use rules live there - do not restate them). This section supplies the foundation **coverage profile** only.

**Coverage profile (caller contract):**

| Parameter | Value |
|-----------|-------|
| **Coverage map** | [Foundation coverage map](reference.md#foundation-coverage-map) (D1–D10) in `reference.md` |
| **Exit gate** | [S4 - Plan-master readiness](#s4--plan-master-readiness) (each dimension maps to one or more S4 criteria) |
| **Ledger path** | `{PLANS_ROOT}/foundation/PROBE_LEDGER.md` |
| **Target** | Coverage ≥ 85%; no gate-blocking dimension below **partial** |

**Sub-modes:** `probe` (one iteration, then stop) · `probe - until ready` (loop to target, ≤5 questions/batch) · `probe - status` (read-only Coverage + gaps; asks nothing).

**Protocol:**

1. Run [GF0](#gf0--bootstrap-artifacts) - need `{HANDOFF}` and foundation doc 01 to record answers into.
2. **ASSESS:** read foundation docs 01–04, ADRs, the three registries, and `PROBE_LEDGER.md` (create from template if absent). Score D1–D10.
3. Run the engine loop (ASSESS → PRIORITIZE → ASK → RECORD → RE-SCORE → EXIT) from [probe-protocol.md](../probe-protocol.md#the-loop).
4. **RECORD** answers to their canonical home (doc 01, ADR **Proposed** stubs, `ASSUMPTIONS`, `UNKNOWNS`, `RISK_REGISTRY`) - never fork lists; never set ADR **Decided** from a probe answer.
5. Update `PROBE_LEDGER.md`; emit the [probe report](../probe-protocol.md#output-report-every-probe-run).
6. **On target reached:** recommend `@plan-foundation certify plan-master-ready` (probe fills gaps; certify + `plan-master integrity` still own the gate).
7. **Relationship to greenfield:** greenfield **embeds** probe at P0 via `p0-probe` (product dimensions only) **before** any technical INTERACTION. Standalone `@plan-foundation probe` is for resume, gap-fill after partial greenfield, or pre-certify polish — not a substitute for the mandatory P0 grill. At later GATEs, run probe again on residual gaps before declaring the gate done.

**Anti-patterns:** see [probe-protocol.md § Anti-patterns](../probe-protocol.md#anti-patterns). In foundation specifically: do **not** use probe to score **implementation-ready** (out of plan-foundation scope - redirect to `@plan-master status`).
---

## Certify protocol (detailed)

<a id="certify-protocol-detailed"></a>

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
- Next: `@plan-master greenfield` or `continue`

### If no
- Blockers: <ordered list>
- Next: `@plan-foundation continue` (missing artifacts) or `@plan-foundation probe` (understanding gaps - vague scope, NFRs, constraints)
```

5. Do **not** create `*-full-plan.md` in certify mode - that is **plan-master**'s job.
---

## Greenfield protocol (detailed)

<a id="greenfield-protocol-detailed"></a>

## Greenfield protocol

0. Run [GF0 - Bootstrap artifacts](#gf0--bootstrap-artifacts).
1. **Project name first** — run `p0-name` before any other INTERACTION unless user already gave the name in the same message.
2. **Initial prompt second** — run `p0-intent`; request the fullest project description the user can provide (paste-friendly). Record verbatim in doc 01 §Founder intent. **Do not** jump to integrations or stack questions here.
3. **Planning registries third** — create empty `{PLANS_ROOT}/ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md` from templates in [Planning registry templates](#planning-registry-templates) (idempotent if already present). **Required before `p0-probe`** — probe records into these files.
4. **Product grill fourth** — run `p0-probe` (probe-protocol loop on D1–D4 + D8 only). Ask until product intent, audience, scope, and core capabilities are understood well enough to infer integrations — or the user defers. **Hard stop:** no `p1-integrations` or `p2-*` until `p0-probe` exits.
5. Create the **P0 initial scope** mini-plan at `{PLANS_ROOT}/foundation/YYYYMMDD-01-<project-slug>-initial-scope.md` (foundation doc 01) after `p0-intent` (update through `p0-probe`). Add placeholder sections for architecture directions (filled in later phases). **Do not** write `{PROMPTS_ROOT}/initial.md` — that path is user-owned scratch; skills read doc 01 instead.
6. **Phase 1 integrations fifth** — run `p1-integrations` only after step 4: agent **infers** likely integrations from product answers, presents the list with rationale, then grills the user on each selected integration.
7. Walk remaining phases P1→P6; at each **GATE**, present checklist + shared integrity; wait for approval before the next phase.
8. Use **Assumption ledger** in foundation doc 01; sync to `ASSUMPTIONS.md` at GATE p1.
9. Apply [Hallucination prevention](#hallucination-prevention) and [Traceability requirement](#traceability-requirement) throughout.
10. Never write broad implementation code until **plan-master** master plan is **Approved** (foundation ends at plan-master-ready).
---

## Foundation concepts (detailed)

<a id="foundation-concepts-detailed"></a>

## Role charter (anti-drift)

**This skill's job ends at `plan-master-ready`.** It does **not** produce or replace the master implementation plan.

| In scope (plan-foundation) | Out of scope (use plan-master or implementation) |
|----------------------------|--------------------------------------------------|
| P0–P6 gates, HANDOFF, NEXT, registries | `*-full-plan.md` authoring |
| `{PLANS_ROOT}/foundation/` docs 01–04 | Milestones M1…, agent task decomposition |
| ADRs, SPECs, CONVENTIONS, directory map | **implementation-ready** certification |
| Certify **plan-master-ready** | Expanding doc 04 into a 25-section execution roadmap |
| Invoke `plan-master integrity` on foundation artifacts | Duplicating plan-master mandatory sections inside foundation files |

**Drift signals (stop and redirect):**

- User asks for "full implementation plan", "roadmap", or "milestones" during foundation work → recommend `@plan-master` after certify.
- Agent merges foundation docs 01–04 into one mega-doc "to finish planning" → **forbidden**; inputs stay separate; plan-master produces the unified roadmap.
- Agent treats `{PLANS_ROOT}/foundation/04` as "the full plan" because the word *plan* appears in the title → **wrong**; doc 04 is **architecture foundation** (proposal), not `{PLANS_ROOT}/full/YYYYMMDD-full-plan.md`.
- Agent scores **implementation-ready** in foundation status → redirect to `@plan-master status`.

---

## Foundation documentation - goals and boundaries

**Canonical folder:** `{PLANS_ROOT}/foundation/` (plan-foundation **P1** output).

These documents are **inputs** to plan-master. They are **not** the plan-master artifact and **must not** be written as if they were.

| Doc | Goal | Must contain | Must NOT become |
|-----|------|--------------|-----------------|
| **01** scope | Unambiguous product scope, audience, assumption ledger, risks | In/out scope, adaptation notes | Full FR/NFR numbered list for whole system (plan-master §3–4) |
| **02** integration | Verified external facts (URLs, APIs, XSDs, OAuth) | Evidence, MANIFEST alignment | Implementation tasks or sandbox run steps (runbook stays in `{PLANS_ROOT}/operations/`) |
| **03** adjacency | Optional product lanes, phased ERP seams, v1 out-of-scope | Integration seams, deferred modules | Execution milestone schedule |
| **04** architecture | Bounded contexts, stack, repo layout, decisions §13, foundation gate §14 | Proposal status, cross-links to 01–03 | **Incremental execution roadmap** (plan-master §19); agent task lists (§24) |

**Cross-cutting foundation outputs (other paths, same phase):**

| Artifact | Goal |
|----------|------|
| `{DECISIONS_ROOT}/` | Record **Decided** architectural choices |
| `{FEATURE_SPEC_ROOT}/*/SPEC` | Per-context **what** (rules R1…, test plan) - not **when/order** |
| `REPLACE:TECH_STACK_DOC` | Pinned stack versions |
| `{PLANS_ROOT}/ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md` | Persistent planning memory (linked by plan-master) |
| `{HANDOFF}`, `{ITERATION_CARRIER}` | Session continuity; NEXT = **one** tactical next action only |

**Explicit non-goals of foundation documentation:**

- Not a single unified implementation plan (that is `*-full-plan.md`).
- Not approved for broad multi-milestone execution until plan-master **Approved**.
- Not a substitute for feature SPECs or ADRs.
- Doc 04 may say "foundation ready" or "gate to start code" - that is **foundation-complete / plan-master-ready** language, **not** implementation-ready.

**When foundation docs are "done":** P1 gate passes + shared integrity - then pursue **plan-master-ready** certification, then `@plan-master greenfield`.

### Terminology (required - prevents confusion with plan-master)

| Avoid in speech and markdown | Use instead |
|------------------------------|-------------|
| "full plan" meaning doc 04 | **architecture foundation** or **foundation doc 04** |
| "the full plan" without a path | Clarify: **architecture foundation** vs **master implementation plan** |
| `*-full-plan.md` | **master implementation plan** (plan-master skill output only) |

**Canonical doc 01 heading (use on greenfield and when fixing legacy text):**

```markdown
## Architecture directions (non-prescriptive - architecture foundation in doc 04)
```

**Canonical doc 01 reference to doc 04 (recommended next artifacts list):**

```markdown
**Architecture foundation (doc 04):** `{PLANS_ROOT}/foundation/YYYYMMDD-04-foundation-architecture.md` - … **Not** the master implementation plan (`*-full-plan.md`).
```

Agents **MUST** use this terminology in status/certify reports when pointing at `{PLANS_ROOT}/foundation/04`. Never call doc 04 "the full plan."

---

## Relationship to plan-master

| Responsibility | Skill |
|----------------|-------|
| Gate progression, repo artifacts, ADR workflows, status/continue/greenfield | **plan-foundation** (this skill) |
| Architecture quality, integrity verification, anti-hallucination, scalability/ops realism, execution decomposition quality | **plan-master** |

`plan-foundation` **orchestrates** the planning lifecycle and repository artifacts.

`plan-master` **governs** planning intelligence: when deep architecture validation, risk analysis, UX/UI strategy depth, implementation decomposition, or AI-agent execution guidance is required, the agent **MUST** read and apply `plan-master/skill.md` (at minimum its [Continuous integrity rules](../plan-master/skill.md#continuous-integrity-rules), [Hallucination prevention](../plan-master/skill.md#hallucination-prevention), and Phase 5 integrity protocol).

**Three readiness states** (foundation owns the first two; plan-master owns the third):

| State | Meaning | Certified by |
|-------|---------|--------------|
| **foundation-complete** | P0–P6 artifact/gate checklists pass | plan-foundation status |
| **plan-master-ready** | Foundation mature enough for master strategic plan | plan-foundation + `plan-master integrity` |
| **implementation-ready** | Master plan validated; safe for broad implementation | **plan-master** status (after Approved `*-full-plan.md`) - **not** plan-foundation |

**When to invoke plan-master during foundation:**

| Trigger | plan-master mode |
|---------|----------------|
| Completing GATE p3, p4, p5, or p6 | **integrity** (subset) or inline checklist |
| Contradictions between ADR and SPEC | **integrity** |
| Before certifying **plan-master-ready** | **integrity** (required) |
| After **plan-master-ready** certified | **greenfield** or **continue** (master plan artifact) |
| **implementation-ready** (user asks) | Redirect to `@plan-master status` - out of plan-foundation scope |
| User asks for roadmap / milestones | **continue** or **status** |

Do not duplicate plan-master content in foundation artifacts - **reference** and **link** traceability rows.

---

## Planning lifecycle (shared with plan-master)

Stages and owners are the three readiness states above, then **Code** (FEATURE_STANDARD + SPECs → application source). Per-stage outputs live in each Phase section and [Master plan artifact](#master-plan-artifact); registries are listed in [Planning registries](#planning-registries-canonical-artifacts).

**Shared terminology:** Phase (P0–P6 foundation) vs Phase (0–6 plan-master) - always prefix **foundation P*** or **plan-master P*** in reports. Never conflate **plan-master-ready** with **implementation-ready**.

---

## Master plan artifact

Produced by **plan-master** after foundation is **plan-master-ready**:

```text
{PLANS_ROOT}/full/YYYYMMDD-full-plan.md
```

Optional sibling for large projects:

```text
{PLANS_ROOT}/full/YYYYMMDD-full-plan-trace.md
```

| Property | Rule |
|----------|------|
| **Owner skill** | plan-master (create/revise); plan-foundation references it |
| **Status** | Draft → Under review → **Approved** → Superseded |
| **Canonical role** | Whole-system implementation roadmap (milestones, NFRs, agent tasks) |
| **When required for implementation-ready** | Status must be **Approved** (or explicit owner waiver in HANDOFF) |
| **Registries** | Links to `ASSUMPTIONS.md`, `RISK_REGISTRY.md`, `UNKNOWNS.md` - no duplicate lists |

plan-foundation **does not** author the master plan and **does not** certify implementation-ready. It **certifies plan-master-ready** so plan-master can run; plan-master **certifies implementation-ready** when the master plan is Approved.

---

## Planning registries (canonical artifacts)

Create at **foundation P0** (empty templates) and maintain through P6. plan-master **reads and extends** these; do not fork duplicate registries inside the master plan (link instead).

| File | Purpose |
|------|---------|
| `{PLANS_ROOT}/ASSUMPTIONS.md` | Confirmed / inferred / rejected / unresolved assumptions (A1…) |
| `{PLANS_ROOT}/RISK_REGISTRY.md` | Architectural, operational, security, scalability, compliance, agent risks (R1…) |
| `{PLANS_ROOT}/UNKNOWNS.md` | Open questions, blocked decisions, deferred concerns (U1…) |

**Rules:**

- Every new assumption during an INTERACTION → append to ASSUMPTIONS with label **Confirmed** | **Inference** | **Unverified**.
- Every identified risk → RISK_REGISTRY with mitigation or **accepted** + owner.
- Every unanswered blocker → UNKNOWNS with owner and **blocks** (gate id or ADR).
- On gate complete → review all three files; resolve or waive explicitly in HANDOFF.

Exploration doc 01 **Assumption ledger** remains the phase-1 capture; sync summaries into `ASSUMPTIONS.md` at GATE p1.

---

## Traceability requirement

Maintain traceability across foundation artifacts:

```text
Business goal → Requirement (FR/NFR or foundation scope)
    → ADR → SPEC (R1… rules) → Implementation task (NEXT / plan-master)
    → Validation/test → Acceptance criterion
```

**Rules:**

- No major requirement in foundation doc 01 or a SPEC **Purpose** without at least one traceability row (in SPEC, plan-master matrix, or HANDOFF table).
- ADRs must reference the requirement or goal they decide.
- SPECs must list **ADRs referenced** and numbered rules (R1…) testable in the test plan.
- At GATE p3+: spot-check traceability; at P6: plan-master integrity must confirm coverage or document waivers.

---

## Gate completion model

A phase is **done** only when **all** are true:

1. Required **artifacts exist** (paths on disk).
2. **[Shared gate integrity](#shared-gate-integrity-every-gate)** checklist passes.
3. **Registries** reviewed (ASSUMPTIONS, RISK_REGISTRY, UNKNOWNS).
4. No **unresolved architectural contradictions** between ADR, foundation doc 04, and SPECs (or waivers in HANDOFF).
5. For P3+: **architecture fitness** subset evaluated (see below).

**Forbidden:** marking a gate `done` because a file exists without semantic review.

---

## Shared gate integrity (every gate)

Append to **every** GATE checklist below:

- [ ] Integrity validation performed (plan-master rules or `plan-master integrity` mode for P3+)
- [ ] `ASSUMPTIONS.md` reviewed; new items labeled
- [ ] `UNKNOWNS.md` updated; blockers explicit
- [ ] `RISK_REGISTRY.md` updated for risks introduced this phase
- [ ] No unresolved contradictions (ADR ↔ SPEC ↔ foundation doc 04)
- [ ] Traceability spot-check for requirements touched this phase

---

## Hallucination prevention

Agents **MUST**:

- Distinguish **Confirmed** (file cite), **Inference**, **Unverified**, **Estimate**.
- Avoid inventing undocumented APIs, framework capabilities, or compliance rules.
- Mark speculative decisions in ASSUMPTIONS and Decision log (ADR).
- Request clarification when uncertain; do not fake certainty.
- Verify critical technical claims against `REPLACE:TECH_STACK_DOC`, ADRs, `.work/docs/integration/`, or official vendor docs.

Prefer proven stack pins and operational simplicity over speculative designs.

---

## Architecture fitness review

At **GATE p3, p4, p5, p6** (and when foundation doc 04 changes), evaluate and record in RISK_REGISTRY or HANDOFF:

| Dimension | Question |
|-----------|----------|
| Scalability | Bottlenecks, growth assumptions realistic? |
| Maintainability | Bounded contexts, clear ownership? |
| Operational complexity | Runbooks, deploy path, on-call surface? |
| Coupling | Forbidden cross-context imports avoided? |
| SPOFs | Single points of failure identified? |
| Extensibility | Feature flags / adjacency lanes documented? |
| Deployment realism | Compose/proposal matches `REPLACE:TECH_STACK_DOC`? |
| Observability | Metrics/traces named for new contexts? |
| Rollback | Migrations, feature flags, deploy order? |
| Security | Threat model + data classification alignment? |

Use plan-master Phase 2/5 depth when the gate is **fail** or **partial**.

---

## UX/UI validation

When `p2-frontend` ≠ `none` or personas exist:

- [ ] Personas or UX principles documented
- [ ] Critical journeys named (counter/desk/owner as applicable)
- [ ] Cognitive load, discoverability, consistency considered
- [ ] Accessibility and responsiveness stated (stack TODO → UNKNOWNS)
- [ ] Error, loading, empty states addressed in SPECs or peripherals SPEC
- [ ] Onboarding and power-user paths noted for ADR 012-style products

Defer deep UX strategy to **plan-master** Phase 3; foundation ensures SPECs and personas are not empty shells.

---

## AI-agent execution optimization

Foundation artifacts **MUST** support downstream coding agents:

- SPECs: numbered rules (R1…), test plan, explicit in/out scope
- DIRECTORY_MAP: folder layout matches bounded contexts
- CONVENTIONS: binding before first merge
- NEXT.md: **one** clear recommended next action
- Tasks in plan-master (post-P6): bounded scope, file paths, acceptance criteria

**Critical paths** (regulated domain, signing, KMS, tenancy): recommend cross-model review in HANDOFF or RISK_REGISTRY.

---

## Cross-model verification

For **Decided** ADRs on stack, tenancy, regulated/signing paths, KMS, or interaction mode:

- Recommend independent review (second model or human) before treating as immutable.
- Record review outcome in ADR or ASSUMPTIONS (**Confirmed** after review).
- At P6: list ADRs that were **not** cross-reviewed as **Unverified** risk if compliance-critical.

---
