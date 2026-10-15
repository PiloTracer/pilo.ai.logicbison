# Agent OS cohabitation audit — pilo-mail

**Created:** 2026-10-15 · **Status:** findings only — **no changes applied**
**Scope:** `.cursorrules` correctness and cross-framework cohabitation for the three installed frameworks
(Agent OS `.ai`, UI Design OS `.ai.ui`, Security OS `.ai.soc`)
**Requested by:** owner, via `@ai-director`

> **This document is a deliverable for the framework authors.** Nothing in `.cursorrules`, in any framework
> source, or in any skill has been modified. Every finding below is reproducible from the evidence cited.

---

## 1. Why this audit exists

The owner asked to verify that `.cursorrules` is correct and that the available frameworks — **three**:
`.ai`, `.ai.ui`, `.ai.soc` — cohabit properly. The goal of the resulting feedback is to improve the
**deployment accuracy and reliability of the source frameworks**, so that a future deployment does not
reproduce these defects.

## 2. Headline result

**All three frameworks' own verifiers report PASS, while the UI integration is substantively incomplete.**

| Verifier | Command | Result |
|----------|---------|--------|
| Agent OS | `cursorrules-verify.sh .` | **PASS** (exit 0) |
| UI Design OS | `cursorrules-verify.sh` | **PASS** (exit 0) — 1 note, 5 warnings |
| Security OS | `soc-deploy-basic.sh verify .` | **all checks passed** (exit 0) |

The repository has a UI **source pointer** but is missing the entire UI **operational contract**: no
`UI_DESIGN_OS_BEGIN/END` block, no UI change-safety gates, no UI completion gate, no UI protected files, no
UI skills list, and no cohabitation boundary. No verifier fails, and none escalates.

That gap between "verifiers are green" and "the integration is incomplete" is the core reliability problem
this feedback is intended to close.

---

## 3. Environment inventory (verified on disk, 2026-10-15)

### 3.1 Frameworks present on the host

| Framework | Directory | `skills/README.md` | `START_HERE.md` | `COHABITATION.md` |
|-----------|-----------|--------------------|-----------------|-------------------|
| Agent OS `.ai` | `pilo.ai.logicbison` | yes | yes | **no** |
| UI Design OS `.ai.ui` | `pilo.ai.ui.logicbison` | yes | yes | yes |
| Security OS `.ai.soc` | `pilo.ai.soc.logicbison` | yes | yes | **no** |
| Business OS `.ai.biz` | `pilo.ai.biz.logicbison` | yes | yes | **no** |
| CTO `.ai.cto` | `pilo.ai.cto.logicbison` | — | — | — |
| Flutter `.ai.flutter` | `pilo.ai.flutter.logicbison` | — | — | — |
| MLT `.ai.mlt` | `pilo.ai.mlt.logicbison` | — | — | — |

`pilo.ai.soc.logicbison.reference` and `pilo.ai.flutter.OfficeToolCombo` also exist and are not frameworks.

### 3.2 What this repository declares and holds

`.cursorrules` is **295 lines**. The source-pointer table at `.cursorrules:44-49` declares **four**
frameworks:

| Row | Framework | Local memory declared | Local memory present |
|-----|-----------|----------------------|----------------------|
| 46 | Agent OS | `.work/` | yes (47 files) |
| 47 | UI Design OS | `.work.ui/` | yes (12 files) |
| 48 | Business OS | `.work.biz/` | **no** |
| 49 | Security OS | `.work.soc/` | yes (8 files) |

So the repository declares **4** frameworks while the owner considers **3** available. See **F-06**.

### 3.3 Section layout of `.cursorrules`

| Lines | Content | Origin |
|-------|---------|--------|
| 1–186 | Agent OS body (identity, principles, change safety, source pointers, project context, skills, protected files, data privacy, mail-domain rules, DB rules, Docker, workflow, verification, documentation layout) | Agent OS customization |
| 188–212 | `## Source resolution — fat-client vs thin-client (UI Design OS)` | **UI — no BEGIN/END markers** |
| 214–295 | `<!-- SOC_DESIGN_OS_BEGIN -->` … `<!-- SOC_DESIGN_OS_END -->` | SOC — markers present |

**Asymmetry:** SOC is a marked, managed block. UI is an unmarked, unmanaged section.

---

## 4. Findings

Severity: **BLOCKER** breaks the repository today · **HIGH** silently degrades capability ·
**MEDIUM** fragility / silent drift · **LOW** cosmetic or robustness.

### F-01 — HIGH — `ui-deploy-basic.sh` merges the **full standalone template**, not the merge snippet

`ui-deploy-basic.sh:112` sets `TPL_CURS="${AI_UI_ROOT}/templates/cursorrules.ui.template"` — the 330-line
**full standalone** template, which contains **no `UI_DESIGN_OS_BEGIN/END` markers**
(`grep -c UI_DESIGN_OS_BEGIN templates/cursorrules.ui.template` → **0**).

The purpose-built merge artifact is `templates/cursorrules.ui.snippet.template` (87 lines), which
**does** carry the markers (`:1`, `:87`) and the complete UI contract. It is never used by the deploy skill.

**Impact:** the thin-client deploy path can never produce a marked, manageable UI block.

### F-02 — BLOCKER — with an existing `.cursorrules`, the UI block is **never written at all**

`write_cursorules()` (`ui-deploy-basic.sh:220-229`) writes only when the target is absent or `force` is used:

```bash
220: write_cursorules() {
222:   if [[ "$force" == "force" ]] || [[ ! -f "$CURS_DEST" ]]; then
224:     echo "  cursorules: wrote (subst AI_UI_SOURCE=$AI_UI_ROOT)"
226:     echo "  cursorules: skip (exists) — keeping existing target .cursorrules"
```

The normal thin-client case is a repository that **already has** `.cursorrules` (Agent OS was deployed
first). There, the default path takes the `skip` branch at `:226` (and again at `:241`), so the UI block is
never merged. Only the source-resolution prose is appended (via `cursorrules-verify.sh --fix`).

**Impact — this is the substantive defect.** The repository receives a UI *pointer* and none of the UI
*contract*. Concretely missing from `.cursorrules`:

- the coexistence boundary (`COHABITATION.md` reference)
- the UI change-safety gate table (touch scope, blast radius, tests, gate check)
- the UI data-loss / destructive-operation union
- the UI completion gate (visual verify + a11y before "done")
- the UI context-file table and placeholder map
- the UI skills table (9 `@ui-*` skills)
- the UI protected-files list

### F-03 — HIGH — the appended UI section has **no `UI_DESIGN_OS_BEGIN/END` markers**

`cursorrules-verify.sh:130-142` (`append_source_resolution`) extracts the section between
`/^## Source resolution/` and the next `^---$` from the **full template** and appends it verbatim. That
extracted text has no markers. Only `REPLACE_BASICUI_SOURCE` is substituted (`:138`).

**Impact — a duplication trap.** `cursorrules-ui.sh` decides whether the block is present by grepping for
the marker (`:22-24`). It will never match, so:

- `status` reports **`UI block: standalone (full UI template)`** (observed, `:51`) — not "merged";
- `merge-block` would see `has_ui_block` as false, skip the guard at `:78-81`, and **append the snippet
  again** (`:82-86`), duplicating UI rules in a file every agent reads;
- `@ui-deploy-basic update` has no delimited region to refresh, so future UI releases cannot update the
  block deterministically.

### F-04 — HIGH — every verifier PASSes on this broken state

- UI `cursorrules-verify.sh:75` accepts a match on `UI_DESIGN_OS_BEGIN|UI Design OS|ui-component-build`, so
  an unmarked section satisfies it: `:76` prints `ok "UI Design OS rules: present"`.
- It *detects* the real problem at `:166-167` but downgrades it to a **`note`**:
  `note "Frameworks registry section: absent (merged-snippet rules?) — ..."`.
- `:272` classifies all remaining `REPLACE:UI_*` tokens as *"operator-filled UI_*: project pins, not a
  failure"*.

**Agent OS** (`cursorrules-verify.sh .`) likewise PASSes and reports the leftover token only as
`[info] REPLACE: tokens remaining: 1`. **SOC** passes all checks.

**Impact:** a deployment that is missing the UI contract is indistinguishable from a healthy one at the CI
gate. This is the single most valuable fix: make the failure detectable.

### F-05 — HIGH — the UI snippet is written for **fat-client**, but is merged into **thin-client** repos

`cursorrules.ui.snippet.template` hard-codes **relative** `.ai.ui/` paths:

```
:14  | Touch scope   | `bash .ai.ui/scripts/touch-scope-verify.sh` |
:15  | Blast radius  | `bash .ai.ui/scripts/blast-radius-check.sh` |
:16  | Tests         | `bash .ai.ui/scripts/framework-verify.sh` |
:17  | Gate check    | `bash .ai.ui/scripts/gate-verify.sh` |
:6   **Coexistence:** [`.ai.ui/COHABITATION.md`](.ai.ui/COHABITATION.md)
:38  | `.ai.ui/COHABITATION.md` | Boundary with Agent OS |
```

The snippet's own header says it is *"Merged by @ui-bootstrap into an existing .cursorrules (typically after
Agent OS)"* — i.e. the thin-client path, where **no local `.ai.ui/` exists** (verified: this repository has
none). No UI script rewrites `.ai.ui/scripts` → `$AI_UI_SOURCE/scripts`; the only occurrence of that string
is prose inside the heredoc (`ui-deploy-basic.sh:212`).

**Contrast — Security OS does this correctly.** The SOC block resolves everything through the pointer:

```
.cursorrules:226  bash $SOC_SOURCE/scripts/soc-deploy-basic.sh verify .
.cursorrules:248  the shared discovery rule ($SOC_SOURCE/scripts/sister-discovery.sh)
```

**Impact:** had the snippet been merged, all four UI gates and the coexistence link would point at
nonexistent paths. UI should adopt SOC's `$AI_UI_SOURCE/...` form.

### F-06 — MEDIUM — Business OS is declared but not deployed

`.cursorrules:48` declares `Business OS | /mnt/work/Projects/pilo.ai.biz.logicbison | .work.biz/`, but
`.work.biz/` **does not exist** and biz is not one of the three installed frameworks.

The Agent OS verifier notices but only informs: `[info] .ai.biz: custom cell value (non-standard — verify
manually)`. The UI verifier emits `warn: .ai.biz: configured path '@biz-director' does not resolve`.

**Impact:** `@biz-director` would resolve a source framework with no local memory directory — an undefined
state. Compare `system-erp`, which has `.work.biz/` present, so it is not inherently impossible; this repo
simply declares a framework it never deployed.

### F-07 — MEDIUM — the `Frameworks registry` heading is a **hard string dependency** that deployers rename

- Canonical heading in the Agent OS template: `templates/cursorrules.template:52` →
  `### Frameworks registry (cross-framework discovery)`
- `x-director/skill.md:20` names it **authoritative**, step 1 of path resolution:
  *"`.cursorrules` § *Frameworks registry* (the file shipped to every adopter repo)."*
- **Six** frameworks' scripts grep for the literal string: `pilo.ai.biz` (`sister-discovery.sh`,
  `framework-verify.sh`), `pilo.ai.cto` (`sister-discovery.sh`, `verify-target.sh`, `deploy-basic.sh`),
  `pilo.ai.flutter` (`deploy-files.sh`, `deploy-verify.sh`, `sister-discovery.sh`, `deploy-basic.sh`),
  `pilo.ai.logicbison` (`sister-discovery.sh`), and UI (`cursorrules-verify.sh:166`).
- **No** framework script greps for the heading both consumer repos actually have: `## Source pointers
  (thin-client — MANDATORY)` (pilo-mail `.cursorrules:42`, and identically in `system-erp:42`).

So the rename happens in **both** consumer repositories, is not performed by `deploy-basic.sh`, and is not
guarded anywhere. The UI verifier's response is a **`note`**, not a warning; `x-director` silently loses its
authoritative source and falls back to heuristics.

**Impact:** cross-framework discovery degrades silently on a step that deployers appear to perform
instinctively. Either enforce/repair the heading, or stop depending on a heading string.

### F-08 — MEDIUM — only UI ships a `COHABITATION.md`

| Framework | `COHABITATION.md` |
|-----------|-------------------|
| `.ai.ui` | present |
| `.ai` | **missing** |
| `.ai.soc` | **missing** |
| `.ai.biz` | **missing** |

The cohabitation contract is therefore single-authored by UI. There is no document that `.ai` and `.ai.soc`
publish their side of the boundary, and none that all three subscribe to.

Worse, the UI snippet's pointer to it is a **relative link** (`:6`) that cannot resolve in the thin-client
mode the snippet targets — so even the one contract that exists is unreachable from the adopter repo.

### F-09 — MEDIUM — `force` can overwrite `.cursorrules` wholesale, contravening the frameworks' own rule

`ui-deploy-basic.sh:237-238` calls `write_cursorules force`, which at `:222-224` writes the **full template**
over `.cursorrules`. That destroys every Agent OS and SOC rule in the file.

The UI snippet itself forbids this behaviour (`snippet:23`): *"MUST NOT … replace `.cursorrules` wholesale
(merge or `confirm-overwrite-cursorrules` only when named)"*. The deploy skill has no such guard — no
`confirm-overwrite-cursorrules` token, no marker-preserving merge.

**Impact:** a plausible operator mistake (`--force` to "refresh the UI rules") silently removes Agent OS
governance from the repository.

### F-10 — LOW — `REPLACE:UI_APP_ROOT` survives deployment, and the verifier normalises it

`.cursorrules:208` still contains `(REPLACE:UI_APP_ROOT)`. Unlike `REPLACE_BASICUI_SOURCE` (which is
substituted by `append_source_resolution`), `UI_APP_ROOT` has **no valid default** and no project here owns
a front-end — this is a mail-server repository with no UI application code.

The verifier's blanket rule at `cursorrules-verify.sh:272` ("UI_* tokens are project pins, not a failure")
means a token that should have been removed or explicitly deferred is reported as acceptable.

### F-11 — LOW — documenting a token by writing the token is a trap for validators

`.cursorrules:196,200,207` legitimately mention `REPLACE_BASICUI_SOURCE` **as prose** (explaining fat-client
mode). Any validator that greps `REPLACE_` (including `grep -c 'REPLACE:UI_'` at `cursorrules-ui.sh:30-36`)
cannot distinguish documentation from an unfilled token. This is why `cursorrules-ui.sh status` reports
`REPLACE:UI_* count: 1` rather than 0.

**Recommendation:** write such tokens as `` `REPLACE_` + `` `BASICUI_SOURCE` `` or in a fenced block, so
they are not greppable as live tokens.

### F-12 — LOW — SOC is the reference model, and its success should be protected

`soc-deploy-basic.sh verify .` passes **all** checks: markers present, no stale `soc-*` handles,
`SOC_SOURCE` reachable with a skills registry, `.work.soc/` skeleton present, and the context-files,
placeholders, skills and Data-Loss-Prevention sections all found. Its paths are pointer-relative
(`$SOC_SOURCE/...`). No action required — recorded so that a future refactor does not regress it.

### F-13 — INFO — sister discovery reports everything on disk, not what is wired

SOC's verify lists **six** sisters as "installed" (`.ai.ui`, `.ai.biz`, `.ai.soc`, `.ai.cto`, `.ai.flutter`,
`.ai.mlt`) because discovery is disk-based, while `.cursorrules` wires only three (plus biz). The output is
accurate but invites the reader to conclude more frameworks are active than are configured.

### F-14 — INFO — three separate verifiers, no single coherence gate

There is no one command that answers *"is this repository's cross-framework configuration coherent?"* Each
framework validates its own slice and tolerates the others' absence. That is precisely how F-02/F-03/F-04
survive three green runs.

### F-15 — LOW — duplicated governance across blocks, with no precedence rule

Each framework block restates rules that Agent OS already owns:

| Rule | Agent OS copy | Sister copy |
|------|---------------|-------------|
| Per-message permission; no destructive ops | Core Principle 8 (`.cursorrules:20`), `## Change safety` (`:25-40`) | SOC `### Data Loss Prevention` (`:287-293`) |
| Change-safety gates | `## Change safety (mechanical)` (`:25-40`) | UI snippet `:10-17` (**would** duplicate, were it merged) |
| Data-loss union | Core Principle 8 | UI snippet `:19-23` |
| Completion gate | Core Principle 7 (`:19`) | UI snippet `:25-27` |

The intent is defensible — a framework wants its invariant present even if Agent OS is absent or in
fat-client mode. The consequences are that the same rule exists twice in a 295-line file read at every
conversation start, the copies can **drift**, and **no precedence rule** says which wins on conflict.

Notably, the UI snippet is *designed* to merge into the existing section — `snippet:10` says
*"Change safety (add to **existing** change-safety section or create one)"* — but the deploy path appends it
as a standalone section instead, so the merge intent is not honoured.

**Recommendation:** each block carries only its **delta** plus a pointer to the normative copy; or full
restatements are explicitly labelled normative vs restatement and a coherence check fails on divergence.

### F-16 — MEDIUM — the UI deploy leaves project-identity tokens unsubstituted in the artifacts it creates

The UI bootstrap commit (`589009a`, "chore: bootstrap UI Design OS thin-client scaffold") created
`DOCS_UI_STACK.md`, which contains **16 unfilled `REPLACE` tokens**, including:

```
DOCS_UI_STACK.md:1   # Front-end stack — REPLACE:PROJECT_NAME
DOCS_UI_STACK.md:11  | Framework | REPLACE:UI_FRAMEWORK (e.g. React 19 + Next.js 15) |
DOCS_UI_STACK.md:30  | App root | `REPLACE:UI_APP_ROOT` |
```

`REPLACE:PROJECT_NAME` is an **Agent OS** token, not a UI one. The UI deploy knows neither the project name
nor the front-end stack, so leaving them is defensible — but the artifact is committed in that state and
nothing in the deploy report says "these 16 tokens are yours to fill". Compare Agent OS's `deploy-basic`,
which explicitly *lists every unfilled `REPLACE:` line and stops*.

**Recommendation:** after writing `DOCS_UI_STACK.md` and the `.work.ui/` skeleton, print an explicit
"operator must fill N tokens" list with `path:line` cites, and exit non-zero in a strict mode.

### F-17 — LOW — the `.work.ui/` skeleton ships unfilled placeholders

Seven files under `.work.ui/` carry `**Updated:** YYYY-MM-DD`, `**Needs:** REPLACE:<decision, review, or
nothing>`, and `REPLACE:UI_RISK_1` / `UA1` / `UU1` style example rows. This may be by design (the `@ui-session`
skill fills them), but it compounds F-04: the UI verifier normalises remaining `REPLACE:UI_*` tokens as
acceptable, so a scaffold that was never completed is indistinguishable from one that was.

**Recommendation:** either fill what the deploy can know (dates, project name) or emit an explicit
"scaffold incomplete — run `@ui-session start`" notice.

### F-18 — MEDIUM — no guard for "this project has no front-end"

pilo-mail contains **zero UI application code** — it is a mail-server repository. The UI framework was
nonetheless deployed, creating a front-end stack document, a `.work.ui/` tree, and UI tokens in
`.cursorrules` for which **no valid value exists** (`UI_APP_ROOT` has no app root to name). The verifier then
reports that token as *"operator-filled UI_*: project pins, not a failure"*.

Deploying UI OS ahead of a future front-end is a legitimate operator choice (a customer portal is Phase C in
this project's roadmap). The defect is that the framework neither detects nor mentions the condition.

**Recommendation:** if no app root is detected, say so during deploy and offer the two honest options —
"defer UI OS until a front-end exists" or "scaffold now, with `UI_APP_ROOT` explicitly recorded as
`N/A — no front-end yet`" rather than leaving a token that cannot be truthfully filled.

---

## 5. What is working correctly (do not regress)

- Agent OS body is intact and customized: **0 `REPLACE:` tokens** in the Agent OS region.
- `AGENT_OS_SOURCE`, `AI_UI_SOURCE` and `SOC_SOURCE` all resolve to reachable directories with readable
  `skills/README.md`.
- The SOC block is correctly marked, pointer-relative, and fully self-verifying.
- `.work/`, `.work.ui/` and `.work.soc/` skeletons exist and are populated.
- The UI **source-resolution** rules themselves are correct and were appended with `AI_UI_SOURCE`
  substituted — the pointer works; only the operational contract is missing.

---

## 6. Consolidated recommendations

Ordered by value. Full detail in the per-framework documents.

| # | Recommendation | Owner framework | Fixes |
|---|----------------|-----------------|-------|
| R1 | Make `ui-deploy-basic.sh` merge `cursorrules.ui.snippet.template`, not the full template | UI | F-01 |
| R2 | On an existing `.cursorrules`, **append the marked snippet** instead of taking the `skip` branch | UI | F-02 |
| R3 | Add a marker-preserving merge path; require `confirm-overwrite-cursorrules` before any wholesale overwrite | UI | F-02, F-09 |
| R4 | Make a missing `UI_DESIGN_OS_BEGIN` block a **FAIL**, not a `note`/`ok` | UI | F-04 |
| R5 | Rewrite all snippet paths to `$AI_UI_SOURCE/...` (copy SOC's pattern) | UI | F-05 |
| R6 | Verify/repair the `Frameworks registry` heading in `deploy-basic`, or parse the table structurally | Agent OS | F-07 |
| R7 | Escalate "declared framework has no local memory directory" to a warning in every verifier | Agent OS | F-06 |
| R8 | Publish `COHABITATION.md` in `.ai` and `.ai.soc`; make it a **required deployment artifact** in every framework | Agent OS, SOC | F-08 |
| R9 | Add one cross-framework coherence command that runs each installed framework's verifier and aggregates | Agent OS | F-14, F-04 |
| R10 | Distinguish *project pins* from *unsubstituted template tokens*; fail on the latter | AI, UI | F-10, F-11 |
| R11 | Ship a machine-readable "installed frameworks" manifest that all verifiers agree on | all | F-13, F-06, F-07 |
| R12 | Document tokens with a non-greppable form so validators cannot mistake prose for a live token | all | F-11 |

---

## 7. Verification plan (for after the fixes land)

A fix is confirmed only when all of the following hold on a **fresh** thin-client deployment over an
existing Agent OS `.cursorrules`:

1. `grep -c 'UI_DESIGN_OS_BEGIN' .cursorrules` → `1`, and `UI_DESIGN_OS_END` → `1`.
2. `cursorrules-ui.sh status` → **not** `standalone`; `has_ui_block` true.
3. Running `merge-block` twice produces **no duplicate** UI rules (idempotency).
4. `cursorrules-verify.sh` → **FAIL** if the UI block is removed (negative test).
5. Every `@ui-*` gate command in the merged block resolves in thin-client mode (no local `.ai.ui/`).
6. `.cursorrules` still contains the Agent OS Core Principles after any `force` attempt without the
   confirmation token.
7. One command reports cross-framework coherence for the three installed frameworks.

---

## 8. Reproduce this audit

```bash
SRC=/mnt/work/Projects/pilo.ai.logicbison
UI=/mnt/work/Projects/pilo.ai.ui.logicbison
SOC=/mnt/work/Projects/pilo.ai.soc.logicbison
T=/mnt/work/Projects/pilo-mail

bash "$SRC/scripts/cursorrules-verify.sh" "$T"               # Agent OS  → PASS
(cd "$T" && bash "$UI/scripts/cursorrules-verify.sh")        # UI        → PASS (note + 5 warnings)
(cd "$T" && bash "$SOC/scripts/soc-deploy-basic.sh" verify .)# SOC       → all checks passed
REPO_ROOT="$T" bash "$UI/scripts/cursorrules-ui.sh" status   # → "UI block: standalone"

grep -c UI_DESIGN_OS_BEGIN "$T/.cursorrules"                 # → 0   (F-03)
grep -c UI_DESIGN_OS_BEGIN "$UI/templates/cursorrules.ui.template"   # → 0   (F-01)
grep -c UI_DESIGN_OS_BEGIN "$UI/templates/cursorrules.ui.snippet.template" # → 1 (unused)
grep -rl 'Frameworks registry' /mnt/work/Projects/pilo.ai.*/scripts/ | wc -l  # → 6+  (F-07)
```

---

## Next action

Route each per-framework document to its framework's maintainer before any change is applied to this
repository. This audit intentionally changed nothing.
