# Skill dependency graph

**Purpose:** Single source of truth for **which skill may run before which**. Skills implement these rules in their own `skill.md` § Prerequisite gates; this file is the registry operators and maintainers read first.

**Invocation punctuation:** Use ASCII hyphen **`-`** between verb and argument (e.g. `@code-implementation plan - M1`, `@feature-spec create - my-slug`, `@process-router - how do I close?`). Do **not** use em dash `—` in commands (hard to type on most keyboards).

## Operator handoff contract (mandatory for every skill)

<a id="operator-handoff-contract"></a>

Implements the operator-provided **Response Clarity Protocol**. Every skill response that ends a turn must be **terse** and close with exactly one of two forms. No skill may invent a third.

**Form A — nothing needed:** a single line stating no user input is required (e.g. `Next: nothing - work complete`). Do not render empty sections.

**Form B — input needed:** end the response with this skeleton; omit any section that has nothing in it; nothing after `**Next step:**`:

```
**Needs your approval:**
1. <Decision> — see path/to/file.md:L42
2. <Decision> — see path/to/file.md (lines 40–45)

**Needs your answer:**
1. <Question>
2. <Question>

**Next step:**
`<exact command or action to run>`
```

Rules:

1. **Brevity.** Report only what changed and what's needed next. No restating the task, no filler transitions, no unrequested rationale. Short declarative sentences.
2. **Exact references.** Approvals cite the project-root-relative path **and** line number(s): `path/to/file.md:L42` or `path/to/file.md (lines 40–45)`. Never make the operator hunt.
3. **Decisions and questions are separate lists.** One decision per numbered item, each answerable with a single yes/no or choice. Questions numbered in their own list, self-contained — answerable without re-reading prior context. Never mix the two in one list.
4. **One next step.** Exactly one command/action, isolated at the end in exact syntax. If multiple sequential actions exist, present only the immediate one; mention later ones only if the operator asks.
5. **Nothing buried, nothing empty.** Never end a response with an unstated expectation; never render an empty section; never hide an operator action inside a paragraph.
6. **Report-internal sections don't replace the close.** A template's "Follow-ups" / "Remaining" / "Recommended next" section is report content; any operator-required approval or question in it must ALSO appear in the Form B close.

**Enforcement:** `scripts/skill-functional-verify.py` fails any `skills/*/skill.md` that does not reference this contract (`Operator handoff`).

## Document clarity contract (mandatory for document-generating skills)

<a id="document-clarity-contract"></a>

Implements the operator-provided **Documentation Clarity Protocol** (origin: `.work/prompts/improve-clarity-of-documentation.md`). Applies to every document a skill generates: plans, proposals, tutorials, guides, reference docs, SPECs, ADRs.

1. **Header answers three questions (≤4 lines):** what it is (one sentence) · **Status** (`Draft` | `In review` | `Approved` | `Superseded` + date) · what it needs (one line, or `nothing`).
2. **Brevity.** Summary first; every section informs a decision or an action; no boilerplate.
3. **Exact references.** Claims cite `path/to/file.md:L42`; quantitative claims tagged `measured` | `estimated` | `assumption` | `unknown`.
4. **Decisions and questions in separate numbered lists** — `## Decisions needed` vs `## Open questions`; never mixed, never buried in prose; each item self-contained.
5. **`## Next action` section** — exactly one action in exact syntax, or one line `Next action: none — <reason>`.
6. **Non-negotiables:** no empty/placeholder sections (omit or write `none` + reason); no document without a Status line; no unstated expectations; template scaffolding (`REPLACE:*`, instructional comments) stripped or filled before a document is presented as complete.

**Enforcement:** `scripts/skill-functional-verify.py` fails any document-generating skill (`docs`, `plan-foundation`, `plan-master`, `feature-spec`) whose `skill.md` does not reference this contract (`Document clarity`).

## Work tree path resolution (mandatory)

**Repository root** (`.git/`, `.cursorrules`) is **not** `{WORK_ROOT}`. All skills resolve placeholders from **repo root** per `.cursorrules` placeholder map (or this table).

| Placeholder | Resolved path | Common wrong path (missing `.work/`) |
|-------------|---------------|--------------------------------------|
| `{WORK_ROOT}` | `.work/` | repo root, `work/` |
| `{HANDOFF}` | `.work/context/HANDOFF.md` | `context/HANDOFF.md`, `HANDOFF.md` |
| `{ITERATION_CARRIER}` | `.work/plans/NEXT.md` | `plans/NEXT.md`, bare `NEXT.md` at repo root |
| `{PLANS_ROOT}` | `.work/plans/` | `plans/` |
| `{FEATURE_SPEC_ROOT}` | `.work/features/` | `features/` |
| `{DOCS_ROOT}` | `.work/docs/` | `docs/` |
| `{DECISIONS_ROOT}` | `.work/decisions/` | `decisions/` |
| `{PROMPTS_ROOT}` | `.work/prompts/` | `prompts/` |
| `{MASTER_PLAN}` | `.work/plans/full/*-full-plan.md` (latest **Approved**) | `plans/full/…` |

**Rule for agents:** In mandatory-read tables, `Read` tool calls, and blocked reports, use the **Resolved path** column. Do not strip the `.work/` prefix. Shorthand (`HANDOFF`, `NEXT.md`) in prose must still mean the resolved path above.

## Frameworks registry resolution (cross-framework skills — mandatory)

`@ai-director` (when redirecting outside `.ai`) and `@x-director` (always) must resolve sibling framework roots in **this exact order** before routing. Never assume a fixed absolute path.

1. **`.cursorrules` § Frameworks registry** — the file shipped to every adopter repo. If it names a path for `.ai.ui` / `.ai.biz` / `.ai.soc`, use it.
2. **Sibling auto-discovery from `.ai` parent:** `parent="$(cd "$REPO_ROOT/.ai/.." && pwd)"; test -d "${parent}/.ai.ui"` (same for `.ai.biz` and `.ai.soc`).
3. **Preflight:** verify `<framework_root>/skills/README.md` is readable before invoking that framework's director. Absent → output one line `framework not installed here` and stop. Never route into the void.

| Framework | Default sibling path | Director | Bootstrap artifact (preflight target) |
|-----------|---------------------|----------|--------------------------------------|
| `.ai` (Agent OS) | *this directory* | `@ai-director` | `skills/README.md` |
| `.ai.ui` (UI Design OS) | `../.ai.ui` | `@ui-director` | `../.ai.ui/skills/README.md` |
| `.ai.biz` (Business OS) | `../.ai.biz` | `@biz-director` | `../.ai.biz/skills/README.md` |
| `.ai.soc` (Social OS) | `../.ai.soc` | `@soc-director` | `../.ai.soc/skills/README.md` |

**Readiness states** (do not conflate):

```text
project-bootstrap (scaffold)
        ↓
foundation-complete  →  plan-master-ready  →  implementation-ready
   plan-foundation        plan-foundation       plan-master status
                          certify
```

| State | Certified by | Unlocks |
|-------|--------------|---------|
| *(scaffold only)* | `@project-bootstrap init` | `@plan-foundation greenfield`, `@session-control` (minimal) |
| **foundation-complete** | `@plan-foundation status` (P0–P6 gates) | `@plan-foundation certify`, foundation **continue** |
| **plan-master-ready** | `@plan-foundation certify` | `@plan-master greenfield` / **continue** / **revise** |
| **implementation-ready** | `@plan-master status` | `@code-implementation start` / **continue** (broad); `@code-implementation plan` *(alias: `plan-iteration`)* with Approved plan |

**M1 early start:** `plan-foundation` may authorize M1 skeleton when **plan-master-ready: yes** and HANDOFF/NEXT document a waiver - that is **not** implementation-ready. `code-implementation` honors HANDOFF milestone waivers per its skill.

---

## Dependency matrix

**Legend:** **Required** = stop and redirect if unmet. **Recommended** = warn, proceed only if user confirms in the same message. **-** = no gate. **Read-only** modes never mutate artifacts.

| Skill / mode | Depends on | Gate |
|--------------|------------|------|
| **project-bootstrap** `init` | Repo contains `.ai/` (or is Agent OS root); **B0** brownfield gate detects existing `.work/` / `.cursorrules` / stack doc | - (brownfield prompts overwrite-all / overwrite-missing / keep / abort) |
| **project-bootstrap** `status` | - | Read-only |
| **session-control** `start` | `{HANDOFF}` (offer bootstrap if missing) | Recommended: `@project-bootstrap init` |
| **session-control** `close` | Prior `start` or dirty tree | - |
| **session-control** `commit` | Dirty tree (offer `start` first if HANDOFF missing) | - |
| **session-control** `context` | - | Read-only (full context load + uncommitted-aware; no HANDOFF writes) |
| **session-control** `status` | - | Read-only |
| **plan-foundation** `greenfield` | `.cursorrules`, `{HANDOFF}` (GF0 gate) | Recommended: `@project-bootstrap init` |
| **plan-foundation** `continue` | Prior foundation work started | - |
| **plan-foundation** `probe` | `{HANDOFF}` + foundation doc 01 to record into (GF0 gate) | Recommended: `@plan-foundation greenfield` if nothing to probe |
| **plan-foundation** `certify` | **foundation-complete: yes** (CF0 gate) | **Required** |
| **plan-foundation** `status` | - | Read-only |
| **plan-master** `greenfield` | **plan-master-ready: yes** (PG1 gate) | **Required** (see exceptions below) |
| **plan-master** `continue` | **plan-master-ready: yes**; draft or partial `*-full-plan.md` | **Required** |
| **plan-master** `probe` | **plan-master-ready: yes** (PG1); Draft/partial `*-full-plan.md` (PG2) | **Required**; run before `integrity` |
| **plan-master** `revise` | Existing `*-full-plan.md`; **plan-master-ready** still valid | **Required** |
| **plan-master** `integrity` | Target artifacts exist (foundation set **or** master plan for P5) | Invoked by plan-foundation certify **or** standalone |
| **plan-master** `status` / `show` *(alias: `task`)* | - | Read-only |
| **plan-verify** `foundation` / `master` / `alignment` | Target artifacts exist for mode (alignment: valid `NEXT` iteration + `{MASTER_PLAN}`) | Read-only; orchestrates plan-foundation status + plan-master integrity; **BF branch** when brownfield |
| **plan-verify** `brownfield` | Code-first or legacy-doc repo; formal plan-foundation/master may never have run | Read-only; framework slot map + substitute paths |
| **plan-verify** `status` | - | Read-only |
| **plan-repair** `repair` / `foundation` / `master` / `brownfield` | Findings from `@plan-verify`, user goal after `-`, or brownfield discovery (R0 gate) | **Recommended:** run source verify if no report in chat |
| **plan-repair** `brownfield` | BF0 = yes; may synthesize `.work/` without prior formal greenfield | May write; re-verify with `@plan-verify brownfield`; formal certify optional after |
| **plan-repair** `status` | - | Read-only |
| **code-implementation** `plan` *(alias: `plan-iteration`)* | Approved `*-full-plan.md` **or** HANDOFF M{N} waiver (PI1 gate) | **Required** |
| **code-implementation** `start` / `continue` | Valid `NEXT.md` iteration block; **implementation-ready** or HANDOFF waiver (ST0 gate); auto-invokes `@code-verify uncommitted` at batch end (see § Self-verify auto-invoke) | **Required** |
| **code-implementation** `complete` | Active iteration; `@code-verify milestone` pass | **Required** |
| **code-implementation** `task` | Active iteration context; shorthand (`T3`) or globally-unique (`M1-T3`) task ID | - |
| **code-implementation** `status` | - | Read-only |
| **code-verify** `milestone` | Active milestone exists in `{MASTER_PLAN}` §19 **or** `NEXT.md` § Current iteration (M0 gate) | **Required** |
| **code-verify** `uncommitted` / `last` | - | - |
| **code-verify** `status` | - | Read-only |
| **code-repair** `repair` (open language / **custom**) | R0-free implementation alignment when no verifier report in chat | **Recommended** before F* rows |
| **code-repair** `repair` | Findings from verifier report, fresh `@code-verify` / `@db-migration verify` / `@feature-spec review`, or **custom** brief (R0 gate) | **Recommended:** run source verifier if no report in chat |
| **code-repair** `status` | - | Read-only |
| **feature-spec** `intake` | None (free-text front door); classifies + routes, only writes a SPEC when class=`local` (then follows `create` gates) | - (read/route; records to `NEXT.md § Intake queue`) |
| **feature-spec** `create` | FEATURE_STANDARD; **CR0** hard-stops if `<slug>/` folder exists; warns if `plan-master-ready: no` | **Required** (brownfield) + **Recommended** (readiness) |
| **feature-spec** `review` / `amend` / `status` / `approve` / `document` | FEATURE_STANDARD; `approve` runs `review` first and only flips Status on pass; `document` has no gates (brownfield-friendly) | - |
| **feature-spec** before **Approved** | §15 concept registry | **Required** per FEATURE_STANDARD |
| **concept-run** `run` | Applicable trigger (SPEC §15, iteration registry, diff scope) | Per `.ai/concepts/README.md` |
| **concept-run** `list` / `status` | - | Read-only |
| **concept-run** `run-all` | Applicable trigger (SPEC §15, iteration registry, diff scope); runs all pending concepts | Per `.ai/concepts/README.md` |
| **db-migration** `init` | Repo at Agent OS root; **IB0** brownfield gate detects existing runner + `001_init.sql` | - (brownfield prompts keep / overwrite-runner / overwrite-all / abort) |
| **db-migration** `create` / `add` / `run` / `verify` | `db-migration init` already run (runner module + `001_init.sql` baseline present); `create` / `add` auto-invokes idempotency double-run (`@db-migration verify` on the new script, see § Self-verify auto-invoke) | **Required** |
| **db-migration** `status` | - | Read-only |
| **deploy-files** (in-place) | Target dir is cwd; source `.ai` resolved (ask if not auto-discoverable) | - (no-overwrite; chains scaffold into target) |
| **deploy-files** `copy` | Target parent dir must exist (I0 gate); source is this `.ai` repo (outbound) | - |
| **deploy-files** `update` | In-place; existing-but-differing files present (merges, never wholesale-replace) | - (no-overwrite + agent rules-aware merge) |
| **deploy-files** `status` | - | Read-only |
| **deploy-basic** (outbound / in-place) | Target dir exists; source `templates/cursorrules.template` readable; warns if target has local `.ai/skills/` (fat-client leak) | - (no-overwrite; writes `AGENT_OS_SOURCE` pointer) |
| **deploy-basic** `update` | Target `.cursorrules` exists (in-place); existing-but-differing local-surface files merged, source pointer re-synced if stale | - (no-overwrite + agent rules-aware merge; never wholesale-replace) |
| **deploy-basic** `status` | - | Read-only |
| **deploy-repo** `clone` | Target must not exist; source must have origin remote (I0 gate) | - |
| **deploy-repo** `archive` | Target parent dir must exist (I0 gate) | - |
| **deploy-repo** `status` | - | Read-only |
| **project-query-setup** `install` / `key` / `test` / `register-mcp` | `python3` available (for MCP server); user has access to tools-project web UI | Optional integration — no gate blocks. On `install`: guides through key creation → key file → MCP registration → live test. |
| **project-query-setup** `status` / `help` | - | Read-only |
| **dev-stack** `init` | User request / `docker-compose*.yml` present; brownfield gate refuses to silently overwrite existing `bin/start.sh` | - |
| **dev-stack** `status` | - | Read-only |
| **docs** `create guide` / `create tutorial` / `create reference` | `.work/docs/` tree exists (created by `@project-bootstrap init`) | Recommended: `@project-bootstrap init` if `.work/docs/` missing |
| **docs** `status` | - | Read-only |
| **tauri-development** `status` | Tauri project with `src-tauri/` directory | Read-only; checks project structure and configuration |
| **tauri-development** `help` | - | Read-only |
| **process-router** `route` / `help` | - | Read-only |
| **ai-director** `- <free-text>` | `.ai/` framework present with valid `skills/README.md` registry; `{HANDOFF}` readable | Recommended: read `{HANDOFF}` + `{ITERATION_CARRIER}` for routing context. **Confirm gate** before any skill invoke (skip with `-y`; render-only with `--dry-run`). Non-`.ai` / cross-framework requests are channelled verbatim to `@x-director` (no framework preflight in ai-director). |
| **ai-director** `- <free-text> -y` | Same as `- <free-text>` | Trust-mode: skips Confirm gate. |
| **ai-director** `- <free-text> --dry-run` | Same as `- <free-text>` | Render routing plan, write nothing, stop. |
| **ai-director** `status` | - | Read-only |
| **ai-director** `review-routing` | `{HANDOFF}` readable with ≥1 `## Latest action (@ai-director)` block | Read-only; aggregates `Routing confidence` / `User correction` entries; surfaces buckets needing signal-table tightening. Never edits the bucket table. |
| **ai-director** `help` | - | Read-only |
| **x-director** `- <free-text>` | At least one framework directory (`.ai/`, `.ai.ui`, `.ai.biz`, `.ai.soc`) must exist; relevant HANDOFF files readable | Recommended: read all present framework HANDOFF files for routing context. **Confirm gate** before any director invoke (skip with `-y`; render-only with `--dry-run`). **Framework preflight** mandatory: resolve roots via `.cursorrules` § Frameworks registry → sibling discovery → read `<fw>/skills/README.md`; absent framework → `framework not installed here`, no route into the void. |
| **x-director** `- <free-text> -y` | Same as `- <free-text>` | Trust-mode: skips Confirm gate. |
| **x-director** `- <free-text> --dry-run` | Same as `- <free-text>` | Render routing plan, write nothing, stop. |
| **x-director** `status` | - | Read-only; marks uninstalled frameworks |
| **x-director** `help` | - | Read-only |

---

## Exceptions and waivers

| Situation | Rule |
|-----------|------|
| **plan-master greenfield** without prior certify | **Forbidden** unless HANDOFF already records `Plan-master-ready: <date>` from a prior certify, or user supplies structured YAML with complete `foundation_docs:` paths **and** confirms foundation was completed out-of-band in the same message. |
| **plan-repair brownfield** without plan-master-ready | **Allowed** — synthesize Draft master plan + HANDOFF `Brownfield-aligned:` / `Brownfield master synthesis:` lines; **implementation-ready** remains **no** until formal Approved plan. |
| **plan-verify brownfield** without foundation docs | **Allowed** — score substitutes (README, ROADMAP, code tree); verdict `aligned-best-effort` not formal certify. |
| **plan-master reference edge case** | Do **not** draft a master plan when foundation is not ready - **stop** and list blockers (see `plan-master/skill.md` § Prerequisite gate). |
| **code-implementation** before **implementation-ready** | **Stop** unless HANDOFF explicitly waives a named milestone (e.g. M1 platform skeleton). |
| **plan-master integrity** on foundation only | Does **not** require an existing `*-full-plan.md`; plan-foundation **certify** invokes this. |
| **feature-spec** during plan-foundation P3 | Expected; SPECs need not wait for plan-master. |
| **db-migration** | Does not require plan-master; requires an implementation task or explicit user request. |

---

## Redirect cheat sheet

| User tried | Blocked because | Run next |
|------------|-----------------|----------|
| `@plan-master greenfield` | Not plan-master-ready | `@plan-foundation status` → `@plan-foundation certify` |
| `@plan-foundation certify` | Not foundation-complete | `@plan-foundation continue` |
| `@plan-foundation greenfield` | No HANDOFF / `.cursorrules` | `@project-bootstrap init` |
| `@code-implementation start` | No iteration block | `@code-implementation plan - M{N}`   *(alias: `plan-iteration`)* |
| `@code-implementation plan` (or `plan-iteration`) | No Approved plan | `@plan-master status` → approve or waiver in HANDOFF |
| `@code-implementation start` | Not implementation-ready | `@plan-master status` or document HANDOFF waiver |
| `@code-verify milestone - M{N}` | Milestone M{N} not in plan / NEXT | `@plan-master show M{N}` or `@code-implementation plan - M{N}` |
| `@db-migration create/run` | `db-migration init` never ran | `@db-migration init` |
| `@feature-spec create - <slug>` | Folder already exists | `@feature-spec amend - <slug>` |
| `@project-bootstrap init` | Repo already bootstrapped | `@project-bootstrap status` (or run `init` with overwrite confirmation) |
| "Ready to code?" in plan-foundation | Wrong skill | `@plan-master status` |
| `@code-verify` / sweep **fail** | Findings need remediation | `@code-repair repair - from uncommitted` (or matching source mode) |
| `@db-migration verify` **fail** | Script not idempotent or runner error | `@code-repair repair - from migration` |
| `@plan-verify` **fail** (foundation/master/alignment) | Plan doc gaps or drift | `@plan-repair repair - from <same mode>` |
| `@plan-repair master` | Not plan-master-ready (formal) | `@plan-repair brownfield` **or** `@plan-repair foundation` → `@plan-foundation certify` |
| Legacy repo, no `.work/plans/` | No formal planning | `@plan-verify brownfield` → `@plan-repair brownfield` |
| Plan gaps during code work | Wrong layer | `@plan-repair` / `@plan-master revise` (not `code-repair`) |
| "Write a guide / tutorial / reference doc" | No docs bucket existed | `@docs create guide - <slug>` or `@docs create tutorial - <slug>` or `@docs create reference - <slug>` |
| "Complete feature definitions for this project" | Multiple features undocumented | `@feature-spec status` then `@feature-spec document - <slug>` per feature |
| "Document an existing feature (brownfield)" | No feature doc exists | `@feature-spec document - <slug>` |
| "I want to build something but don't know which skill" | Unsure which skill to use | `@ai-director - <describe what you want>` |
| "I need UI work done" | UI work requires `.ai.ui` framework | `@ui-director` (via `.ai.ui` director) or `@x-director - <request>` |
| "I need business strategy work" | Business work requires `.ai.biz` framework | `@biz-director` (via `.ai.biz` director) or `@x-director - <request>` |
| "I need social / community work done" | Social work requires `.ai.soc` framework | `@soc-director` (via `.ai.soc` director) or `@x-director - <request>` |
| Cross-framework request (e.g. full-stack feature) | Spans multiple frameworks | `@x-director - <request>` (coordinates across directors) |
| Scope/NFRs/constraints vague; "do you understand the project?" | Understanding gap, not artifact gap | `@plan-foundation probe` (then `certify`) |
| Plan has vague NFRs / unmapped FRs / ownerless risks | Plan-completeness gap | `@plan-master probe` → `@plan-master integrity` |

---

## Canonical command vocabulary

All skills use the same verbs where applicable. This keeps muscle memory portable.

| Canonical verb | Meaning | Skills that implement it |
|----------------|---------|---------------------------|
| `status` | Read-only: report current state | plan-foundation, plan-master, plan-verify, plan-repair, session-control, code-implementation, code-verify, code-repair, feature-spec, db-migration, concept-run, dev-stack, project-bootstrap, docs |
| `repair` | Fix reported issues; re-verify | code-repair, plan-repair |
| `verify` | Audit planning artifacts (foundation / master / alignment) | plan-verify |
| `probe` | Adaptive gap-driven interrogation loop; scores knowledge/plan coverage, asks targeted questions, fills gaps into registries. **New verb** (distinct from `status` read-only, `continue` resume-phase, `integrity` auto-sweep). Engine: [`probe-protocol.md`](probe-protocol.md) | plan-foundation, plan-master |
| `commit` | Git commit/push without close | session-control |
| `context` | Read-only full context load + uncommitted-aware summary; no writes | session-control |
| `start` | Begin a unit of work | session-control, code-implementation |
| `continue` | Resume in-progress work | plan-foundation, plan-master, code-implementation |
| `continue` + target (`code-implementation` only) | Batch tasks: `- N`, `- until blocked`, `- M{N}-T{a}..T{b}`; stop on gate fail or blocker | code-implementation |
| `close` | Wrap up + handoff | session-control |
| `complete` | Mark a unit as done | code-implementation |
| `plan` | Prepare next unit | code-implementation *(alias: `plan-iteration`)* |
| `init` | One-time setup | project-bootstrap, db-migration, dev-stack |
| `update` | Rules-aware merge of existing-but-differing files (append new, update shared, preserve target customizations, never wholesale-replace) | deploy-files, deploy-basic |
| `intake` | Classify a free-text feature request → route to the right executor; records to `NEXT.md § Intake queue` (does not auto-execute cross-cutting/brownfield paths) | feature-spec |
| `create` | Make a new artifact | feature-spec, db-migration, docs |
| `amend` | Modify an existing artifact | feature-spec |
| `review` | Read-only audit of an artifact | feature-spec |
| `revise` | Structured edit | plan-master |
| `certify` | Formal sign-off transitioning a readiness state | plan-foundation |
| `greenfield` | First-time creation | plan-foundation, plan-master |
| `verify` / `milestone` / `uncommitted` / `last` | Runtime/output checks | code-verify (scope flag), db-migration; **plan-verify** uses `foundation` / `master` / `alignment` (not bare `verify` alone) |
| `brownfield` | Discover/create missing planning artifacts from existing repo | plan-repair |
| `alignment` / `drift` | NEXT vs master plan consistency | plan-verify (read-only), plan-repair (fix) |
| `run` | Execute (scripts / prompts) | db-migration, concept-run |
| `run-all` | Execute all pending concept prompts for the current iteration | concept-run |
| `show` | Read-only inspect of a specific record | plan-master *(alias: `task`)* |
| `task` | Execute a single task by shorthand or globally-unique ID (active iteration context) | code-implementation |
| `- <free-text>` | Free-text routing: parse intent → classify → Confirm gate → execute skill chain | ai-director, x-director |
| `- <free-text> -y` | Trust-mode: skip the Confirm gate | ai-director, x-director |
| `- <free-text> --dry-run` | Render the routing plan, write nothing, stop | ai-director, x-director |
| `review-routing` | Read-only aggregate of `Routing confidence` / `User correction` HANDOFF entries; surface buckets needing signal-table tightening | ai-director |
| `help` | Display skill's purpose, registry, and invocation examples | ai-director, x-director |
| `list` | Enumerate available items | concept-run |
| `route` / `help` | Read-only Q&A | process-router |

**Alias policy:** When a verb is renamed, the old name is kept as an alias for **at least one minor version**. Aliases are listed inline in each skill's parse-invocation table and in the matrix above.

---

<a id="blocked-report-shape"></a>

## Blocked report shape (every gate)

When a gate stops execution, the skill emits a uniform block so users always see the same shape:

```markdown
## @<skill> <command> - blocked (prerequisite)

**Required:** <state or upstream step>
**Detected:** <what's actually present>
**Run first:** `<exact command to fix>`
```

Skills must not invent ad-hoc error messages for prerequisite failures.

---

## Self-verify auto-invoke

Some mutating skills must invoke a verifier on the artifact they just produced **before** declaring the mode complete. This is in addition to per-step mechanical gates and prevents "issues surface only after the user prompts again".

| Skill / mode | Auto-invokes | When | Skip allowed? |
|--------------|--------------|------|----------------|
| `code-implementation` `continue` (any `-` target) | `@code-verify uncommitted` over cumulative batch diff (see `code-implementation` § Batch-end sweep) | After per-task loop ends, before Batch summary | Only when zero files changed during the loop |
| `code-implementation` `complete` | `@code-verify milestone` | CO2, before final gates | No |
| `db-migration` `create` / `add` | `@db-migration verify` (or `run` twice in dev DB) on the new script | C6, before declaring create complete | Only when DB not reachable; record reason |
| `feature-spec` `approve` | `@feature-spec review` | Before flipping `Status: Approved` | No |

**Honesty:** Auto-invoked verifiers run with the **same evidence rules** as standalone invocations. A `pass` claim without exit code, file path, or quoted output is treated as `unverified` per `.cursorrules` Core Principle 5.

**Post-fix re-gate** (separate from auto-invoke): when an agent applies a fix in response to **any** reported issue, the affected task's gate **must** be re-run before claiming repair. See `code-implementation` § Post-fix re-gate.

---

## Maintenance

When adding or changing a skill:

1. Update this matrix and (if a new verb is introduced) the canonical vocabulary above.
2. Add or update § **Prerequisite gate** in that skill's `skill.md` using the **blocked report shape**.
3. Add a row to `process-router/reference.md` if operators commonly hit the gate.
4. Do **not** duplicate normative gate text in START_HERE beyond the readiness diagram - link here or to the skill.
5. Prefer **reusing an existing canonical verb** over inventing a new one. If a new verb is unavoidable, document why.
