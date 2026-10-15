# Feedback → UI Design OS (`.ai.ui`)

**From:** pilo-mail cohabitation audit, 2026-10-15
**Audit reference:** `20261015-cohabitation-audit.md` (findings F-01, F-02, F-03, F-04, F-05, F-09, F-10, F-11)
**Status of this document:** recommendations only — **no framework source was modified**

> **One-line summary:** in the thin-client path — the path the snippet is explicitly designed for — the UI
> block is never merged, and when a section *is* appended it is unmarked, so the deployment is missing the
> whole UI operational contract while `cursorrules-verify.sh` reports **PASS**.

---

## 1. Impact on the adopter repository

`pilo-mail/.cursorrules` (295 lines) contains a UI **source pointer** and no UI **contract**. Missing:

| Expected in `.cursorrules` | Present? | Source of expectation |
|----------------------------|----------|------------------------|
| `<!-- UI_DESIGN_OS_BEGIN -->` / `END` | **no** | `cursorrules.ui.snippet.template:1,87` |
| Coexistence pointer to `COHABITATION.md` | **no** | `snippet:6` |
| UI change-safety gate table (4 gates) | **no** | `snippet:12-17` |
| UI data-loss / destructive-operation union | **no** | `snippet:19-23` |
| UI completion gate (visual + a11y) | **no** | `snippet:25-27` |
| UI operator handoff contract | **no** | `snippet:29-31` |
| UI context-file table + placeholder map | **no** | `snippet:33-63` |
| UI skills table (9 `@ui-*` skills) | **no** | `snippet:65-79` |
| UI protected-files list | **no** | `snippet:81-85` |
| Source-resolution rules | yes (unmarked) | appended from the full template |

Net effect: an agent working in this repository has the UI **pointer** and none of the UI **rules**.

---

## 2. F-01 / F-02 — the deploy skill merges the wrong artifact, and skips when one is needed

**Evidence**

```bash
# 112: the FULL standalone template is the merge source
TPL_CURS="${AI_UI_ROOT}/templates/cursorrules.ui.template"

# 220-229: written only when absent or forced
write_cursorules() {
  if [[ "$force" == "force" ]] || [[ ! -f "$CURS_DEST" ]]; then
    subst_cursorules > "$CURS_DEST"
    echo "  cursorules: wrote (subst AI_UI_SOURCE=$AI_UI_ROOT)"
  else
    echo "  cursorules: skip (exists) — keeping existing target .cursorrules"
  fi
}
```

```bash
grep -c UI_DESIGN_OS_BEGIN templates/cursorrules.ui.template          # 0  ← used
grep -c UI_DESIGN_OS_BEGIN templates/cursorrules.ui.snippet.template  # 1  ← never used
```

Thin-client bootstrap normally targets a repository that **already has** `.cursorrules` (Agent OS deployed
first), so the `skip` branch is the *expected* path — and the UI block is never written.

**Recommended change**

1. Point the merge at the snippet:
   `SNIP_TPL="${AI_UI_ROOT}/templates/cursorrules.ui.snippet.template"` and use it whenever
   `.cursorrules` already exists.
2. Replace the `skip` branch with an append of the marked snippet. The existing guard in
   `cursorrules-ui.sh:78-81` (`skip: UI_DESIGN_OS_BEGIN already present`) is the correct idempotency
   primitive — it just needs the marker to exist.
3. Keep the full template for the genuine "no `.cursorrules` at all" case (`create-full`).

**Acceptance:** on a repo with a pre-existing Agent OS `.cursorrules`, running the thin-client deploy yields
`grep -c UI_DESIGN_OS_BEGIN .cursorrules` → `1`; running it twice still → `1`.

---

## 3. F-03 — the appended section is unmarked, which creates a duplication trap

**Evidence** — `cursorrules-verify.sh:130-142` appends text extracted from the **full** template:

```bash
130: append_source_resolution() { # $1 = template path, $2 = source value (thin) or ""
137:     awk '/^## Source resolution/{f=1} f&&/^---$/{exit} f' "$tpl" \
138:       | perl -pe "s/AI_UI_SOURCE=REPLACE_BASICUI_SOURCE/AI_UI_SOURCE=${esc}/"
```

`cursorrules-ui.sh` decides presence by marker:

```bash
22: has_ui_block() { grep -q 'UI_DESIGN_OS_BEGIN' "${RULES}"; }
51:   echo "  UI block: standalone (full UI template)"
78:   if has_ui_block; then echo "skip: UI_DESIGN_OS_BEGIN already present"; exit 0; fi
86:   echo "merged: UI block appended to ${RULES}"
```

Observed on this repository:

```
$ REPO_ROOT=/mnt/work/Projects/pilo-mail bash scripts/cursorrules-ui.sh status
  UI block: standalone (full UI template)
  REPLACE:UI_* count: 1
```

Because `has_ui_block` is false, `merge-block` would **append the snippet a second time**, duplicating UI
rules in a file read at the start of every conversation.

**Recommended change**

- Wrap every programmatic append in the markers, or refuse to append unmarked text.
- In `append_source_resolution`, emit `<!-- UI_DESIGN_OS_BEGIN -->` … `<!-- UI_DESIGN_OS_END -->` around
  the appended region (or delegate to the snippet).
- Add a duplicate guard: if a second `## UI Design OS` heading is about to be created, abort.

---

## 4. F-04 — the verifier passes on the broken state (highest-value fix)

**Evidence**

```bash
75: if grep -qE 'UI_DESIGN_OS_BEGIN|UI Design OS|ui-component-build' "$RULES"; then
76:   ok "UI Design OS rules: present"
...
166: if ! grep -q 'Frameworks registry' "$RULES"; then
167:   note "Frameworks registry section: absent (merged-snippet rules?) — sisters resolve by on-disk auto-discovery only"
...
272: note "REPLACE tokens remaining: ${total} (operator-filled UI_*: ${ui_only}) — UI_* tokens are project pins, not a failure"
```

Observed verdict: `cursorrules-verify: PASS` with `ok: UI Design OS rules: present`.

A **note** is not a signal. The precise condition this deployment fails — "the merged-snippet rules are
absent" — is known to the verifier and is not treated as a failure.

**Recommended change**

1. Treat a missing `UI_DESIGN_OS_BEGIN` block as **FAIL** whenever the repository is in thin-client mode
   (`AI_UI_SOURCE` set). Accept `UI Design OS` string matches only for the declared **fat-client**
   standalone case, and report which mode justified the pass.
2. Escalate `Frameworks registry section: absent` from `note` to `warn` at minimum, because it changes
   `x-director`'s path resolution from authoritative to heuristic.
3. Split `:272`: a `REPLACE:UI_*` token that is a **project pin** (e.g. `UI_TOKENS_FILE`) is acceptable; a
   token with **no valid default that no project here can satisfy** (e.g. `UI_APP_ROOT` on a repo with no
   front-end) should be `warn`, not silently normalised.

**Acceptance:** deleting the UI block from a correctly-merged `.cursorrules` makes
`cursorrules-verify.sh` exit non-zero.

---

## 5. F-05 — the snippet uses fat-client relative paths in a thin-client artifact

The snippet is documented as *"Merged by @ui-bootstrap into an existing .cursorrules (typically after Agent
OS)"* — the thin-client case, where **no local `.ai.ui/` exists** (verified: `pilo-mail/.ai.ui` absent).
Yet it hard-codes relative paths:

```
:14  | Touch scope   | `bash .ai.ui/scripts/touch-scope-verify.sh` |
:15  | Blast radius  | `bash .ai.ui/scripts/blast-radius-check.sh` |
:16  | Tests         | `bash .ai.ui/scripts/framework-verify.sh` |
:17  | Gate check    | `bash .ai.ui/scripts/gate-verify.sh` |
:6   **Coexistence:** [`.ai.ui/COHABITATION.md`](.ai.ui/COHABITATION.md)
:38  | `.ai.ui/COHABITATION.md` | Boundary with Agent OS |
```

No UI script rewrites `.ai.ui/scripts` → `$AI_UI_SOURCE/scripts`; the only occurrence of that string is
prose inside a heredoc (`ui-deploy-basic.sh:212`).

**Security OS already solves this** — copy its pattern:

```
.cursorrules:226  bash $SOC_SOURCE/scripts/soc-deploy-basic.sh verify .
.cursorrules:248  ($SOC_SOURCE/scripts/sister-discovery.sh)
```

**Recommended change:** in `cursorrules.ui.snippet.template`, resolve every path through the pointer:

| Line | Replace with |
|------|--------------|
| 14 | `bash $AI_UI_SOURCE/scripts/touch-scope-verify.sh` |
| 15 | `bash $AI_UI_SOURCE/scripts/blast-radius-check.sh` |
| 16 | `bash $AI_UI_SOURCE/scripts/framework-verify.sh` |
| 17 | `bash $AI_UI_SOURCE/scripts/gate-verify.sh` |
| 36–45 | `$AI_UI_SOURCE/START_HERE.md`, `$AI_UI_SOURCE/standards/...` |
| 6, 38 | `$AI_UI_SOURCE/COHABITATION.md` |

Keep `.work.ui/...` relative — that IS local in thin-client mode.

---

## 6. F-09 — `force` can destroy the Agent OS rules

`ui-deploy-basic.sh:237-238` → `write_cursorules force` → `:222-224` writes the full template over
`.cursorrules`, removing every Agent OS and SOC rule in the file.

The snippet forbids exactly this (`:23`): *"MUST NOT … replace `.cursorrules` wholesale (merge or
`confirm-overwrite-cursorrules` only when named)"*.

**Recommended change:** require the literal `confirm-overwrite-cursorrules` token (as `create-full` already
does at `cursorrules-ui.sh:64`) before any wholesale overwrite, and print a diff summary of the sections
that would be lost.

---

## 7. F-10 / F-11 — token hygiene

- `.cursorrules:208` carries `(REPLACE:UI_APP_ROOT)` — a token with no valid default in a repository with no
  front-end. Either drop it from the source-resolution section or emit it as an explicit
  `N/A — no front-end in this project` line.
- Snippet/heredoc prose that mentions `REPLACE_BASICUI_SOURCE` is indistinguishable from a live token to
  `grep`. `cursorrules-ui.sh:30-36` (`count_ui_replace`) counts it. Write such references in a
  non-greppable form (e.g. inside a fenced block, or as `` `REPLACE_`+`BASICUI_SOURCE` ``).

---

## 8. Additional cohabitation items

### 8.1 — the snippet is designed to **merge into** the Agent OS change-safety section, but is appended as a second one

`cursorrules.ui.snippet.template:10` reads:

> `### Change safety (add to existing change-safety section or create one)`

The intent is explicit: the four UI gates belong **inside** the existing Agent OS
`## Change safety (mechanical)` table, so an agent reads one gate table. The deploy path instead appends the
snippet as a separate top-level section, producing two change-safety tables in one file — one of which the
Agent OS tooling (`blast-radius-check.sh`, `touch-scope-verify.sh`) does not know about.

**Recommended change:** either perform the section merge (hard in Markdown, but doable by targeting the
existing table), or drop the parenthetical and accept two clearly-labelled tables. Today the comment
promises a merge that the code cannot deliver.

### 8.2 — duplicated governance with no precedence rule

The snippet restates the permission and data-loss rules that Agent OS owns in Core Principles 7–8
(`snippet:19-27`). Combined with SOC doing the same thing (`.cursorrules:287-293`), a three-framework
repository carries the same governance in three places with no stated precedence if they diverge. See the
audit's **F-15**; the recommendation is delta-plus-pointer rather than full restatement.

### 8.3 — the artifacts the deploy *does* create are left with unfilled tokens

The UI bootstrap commit `589009a` ("chore: bootstrap UI Design OS thin-client scaffold (.work.ui,
DOCS_UI_STACK, cursorrules source resolution)") added 330 lines across 14 files. The commit message is itself
corroborating evidence for F-01/F-02: it describes adding **"cursorrules source resolution"** — 28 insertions
— and not the 87-line UI contract.

Two consequences visible in that commit:

- **`DOCS_UI_STACK.md` carries 16 unfilled `REPLACE` tokens**, including `REPLACE:PROJECT_NAME` — which is an
  **Agent OS** token the UI framework cannot know. Agent OS's `deploy-basic` lists every unfilled token and
  stops; the UI deploy commits them silently.
- **Seven `.work.ui/` files** ship `**Updated:** YYYY-MM-DD` and `REPLACE:` example rows. Filling the date is
  within the deploy's knowledge and is not done.

**Recommended change:** end the deploy with an explicit operator action list —
`N tokens require your input: path:line …` — and offer a strict mode that exits non-zero. This is the
cheapest single improvement to deployment reliability after F-04.

### 8.4 — no guard for "this project has no front-end"

This repository contains **no UI application code**; it is a mail server. UI OS was still deployed, so
`DOCS_UI_STACK.md` describes a stack that does not exist and `REPLACE:UI_APP_ROOT` (`.cursorrules:208`) can
never be truthfully filled.

Deploying ahead of a future front-end is a valid operator decision. The gap is that the framework does not
notice or mention it.

**Recommended change:** detect the absence of an app root during deploy and say so, offering
*"defer until a front-end exists"* or *"scaffold now and record `UI_APP_ROOT` as `N/A — no front-end yet`"*.
A token that cannot be truthfully answered should not be left looking unanswered.

---

## 9. Suggested order of work

| Order | Change | Fixes | Effort |
|-------|--------|-------|--------|
| 1 | Missing `UI_DESIGN_OS_BEGIN` → FAIL in `cursorrules-verify.sh` | F-04 | S |
| 2 | Merge the snippet (not the full template) into an existing `.cursorrules` | F-01, F-02 | M |
| 3 | Marker-wrap every programmatic append; add a duplicate guard | F-03 | S |
| 4 | Pointer-relative paths throughout the snippet | F-05 | S |
| 5 | `confirm-overwrite-cursorrules` guard on `force` | F-09 | S |
| 6 | Token hygiene | F-10, F-11 | S |

Doing **(1) first** is deliberate: it converts this class of silent mis-deployment into a red gate, which is
what prevents recurrence even before the merge logic is rewritten.

---

## Next action

Apply R1–R5 and R10 in the UI Design OS source, then re-run the verification plan in
`20261015-cohabitation-audit.md` §7 against a fresh thin-client target.
